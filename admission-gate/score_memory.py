"""Admission-gate baseline scorer -- Python port.

Faithful port of ``admission-gate/score-memory.ps1``. Same labeled fixture is
the cross-language contract: both scorers must produce identical per-item
decisions on every fixture in ``admission-gate/fixtures/``. The PS version
remains the source of truth for CI gating today; this Python version exists
so the same rules can be embedded as middleware in pipelines that are not
PowerShell-native (mem0, langchain, custom MCP servers, etc.).

Run from repo root::

    python admission-gate/score_memory.py
    python admission-gate/score_memory.py --verbose
    python admission-gate/score_memory.py --fail-under 85
    python admission-gate/score_memory.py \\
        --fixture admission-gate/fixtures/real-memory.jsonl --unlabeled

Exit codes mirror the PS version: 0 ok, 2 fixture missing/malformed,
3 accuracy below ``--fail-under``.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path


# ---------------------------------------------------------------------------
# Rule data. Kept structurally close to the PS file so a side-by-side diff
# stays cheap to verify.
# ---------------------------------------------------------------------------

REUSABILITY_NEGATIVE_PATTERNS = [
    r"\b(today|yesterday|tomorrow|just now)\b",
    r"\b(at|on)\s+\d{1,2}[:.]\d{2}\b",
    r"\b20\d{2}-\d{2}-\d{2}\b",
    r"\b(office-pc|workstation|laptop-\w+)\b",
    r"\bline\s+\d+\b",
    r"\bsrc/[a-zA-Z0-9_./-]+",
    r"\bfeature/[a-zA-Z0-9._-]+",
    r"\bsprint-?\d+\b",
    r"\b(named|aged?\s+\d+|years old|lives in)\b",
    r"\bacme\b|\bcustomer-\w+\b",
]

CONTRADICTION_STOPWORDS = {
    "the", "a", "an", "some", "any", "to", "for", "on", "in", "of", "and",
    "or", "but", "with", "that", "it", "its", "this", "these", "those",
    "your", "their", "my", "our", "use", "do", "be", "have", "make", "take",
    "get", "give", "call",
}

# Iter-10: claim-extraction stopwords for contradiction-against-store.
# Broader than CONTRADICTION_STOPWORDS so subject sets compare cleanly.
CLAIM_STOPWORDS = {
    "the", "a", "an", "some", "any", "to", "for", "on", "in", "of", "and",
    "or", "but", "with", "that", "it", "its", "this", "these", "those",
    "your", "their", "my", "our", "do", "be", "have", "make", "take",
    "get", "give", "call", "as", "at", "by",
    "is", "are", "was", "were", "when", "if", "before", "after", "from",
    "into", "instead", "over", "under", "about", "because", "since", "so",
    "then", "than", "too", "very", "not", "no", "only", "also", "both",
    "either", "neither",
    "can", "will", "would", "should", "must", "may", "might", "could",
    "you", "we", "they", "he", "she", "i", "them", "us", "here", "there",
}

# Polarity markers, ordered: multi-word first.
_CLAIM_MARKERS: list[tuple[str, str]] = [
    ("do not", "-"),
    ("don't", "-"),
    ("never", "-"),
    ("avoid", "-"),
    ("always", "+"),
    ("prefer", "+"),
    ("ensure", "+"),
    ("require", "+"),
]
_CLAIM_TAIL_PATTERNS = [(re.compile(rf"\b{re.escape(m)}\b\s+(.+)", re.IGNORECASE), p) for m, p in _CLAIM_MARKERS]
_CLAIM_TOKEN_RE = re.compile(r"[a-z0-9_-]+")


ACTIONABLE_VERBS = [
    "always", "never", "prefer", "use", "check", "run", "add", "set",
    "avoid", "verify", "ensure", "promote", "request", "require",
]

VAGUE_FILLERS = [
    "matters", "should care", "is important", "quality", "best practice",
    "various", "generally", "sometimes",
]

TECH_PROPER_NOUNS = {
    "Always", "Never", "Prefer", "Use", "Check", "Run", "Set", "Avoid",
    "Verify", "Ensure", "When", "If", "Before", "After", "For", "In", "On",
    "A", "An", "The", "This", "These",
    "Avalonia", "Salesforce", "MuleSoft", "DataWeave", "Apex", "PowerShell",
    "Pwsh", "Python", "MkDocs", "GitHub", "GitLab", "Linux", "Windows",
    "MacOS", "Docker", "Kubernetes", "React", "Vue", "Angular", "Node",
    "TypeScript", "JavaScript", "Rust", "Java", "Kotlin", "Swift", "Ruby",
    "Bash", "VS", "Visual", "Code", "Studio", "Microsoft", "Google",
    "Amazon", "AWS", "Azure", "OpenAI", "Claude", "Copilot", "Cursor",
    "Windsurf", "Cline", "Gearset", "Mocha", "Jest", "Pytest", "Jupyter",
    "Git", "Mercurial", "Jenkins", "CircleCI",
}


def _ci(pattern: str) -> re.Pattern[str]:
    return re.compile(pattern, re.IGNORECASE)


def _cs(pattern: str) -> re.Pattern[str]:
    return re.compile(pattern)


# Pre-compile every rule once. Tuple of (compiled, penalty).
_REUSE_NEG = [_ci(p) for p in REUSABILITY_NEGATIVE_PATTERNS]

# Actionability rules expressed as a flat list of (compiled, penalty, mode).
# mode: "ci" = case-insensitive search on text, "cs" = case-sensitive.
# Order is preserved from the PS file; rules are independent (no short-circuit).
_ACTIONABILITY_RULES: list[tuple[re.Pattern[str], float, str]] = [
    (_ci(r"\bif\s+.+\bthen\b.+\b(is|returns?)\b"), -1.0, "ci"),
    (_ci(r"\bagent\b.*\b(answered|responded|said)\b"), -0.75, "ci"),
    (_ci(r"\b(sunny|raining|wifi|weather)\b"), -1.0, "ci"),
    (_ci(r"\b(heartbeat|still alive|no new observations?|sync interval|keep[- ]?alive)\b"), -1.5, "ci"),
    (_ci(r"\b(todo|tbd|fixme|wip|xxx)\b"), -1.5, "ci"),
    (_ci(r"\b(loading complete|system ready|ready for input|all systems (go|ok)|startup complete|booted up)\b"), -1.5, "ci"),
    (_ci(r"\buser\s+(clicked|tapped|hovered|opened|closed|typed|scrolled|navigated|pressed|selected|dragged)\b"), -1.5, "ci"),
    (_ci(r"\b(it depends|hard to say|could be either|not sure|who knows)\b"), -1.0, "ci"),
    (_ci(r"\b(rolling out|in progress|currently\s+(running|deploying|processing|building|loading))\b"), -0.5, "ci"),
    (_ci(r"\b(worked|broke|crashed|failed|happened)\s+when\s+(i|we)\b"), -1.5, "ci"),
    (_cs(r"\b[A-Z][a-z]+\s+from\s+(accounting|marketing|sales|finance|hr|support|ops|engineering|product|legal|it|the\s+\w+\s+team)\b"), -1.5, "cs"),
    # Named-person Pattern B handled separately below (needs allowlist check).
    (_ci(r"\b(coffee|tea|lunch|breakfast|dinner|office|room|building|hallway|weather|wifi|internet|aircon|heater)\b.*\b(was|is)\s+(cold|hot|loud|quiet|warm|noisy|busy|calm|fast|slow|broken|down)\b"), -1.5, "ci"),
    # Heading-only is checked on the original $t (case preserved); pattern is case-insensitive-friendly anyway.
    (_ci(r"^.{1,80}:\s*$"), -1.5, "ci"),
    (_ci(r"\bwe should\s+(be\s+(better|able|good|careful|nicer|more|less)|do|try|make|consider)\b"), -1.5, "ci"),
    (_ci(r"\b(generally|usually|mostly|often)\s+(faster|slower|better|worse|easier|harder|simpler|cheaper|nicer)\s+than\b"), -1.5, "ci"),
    (_ci(r"^sorry,?\s|\bi\s+(missed|forgot to see|didn'?t see)\s+your\b"), -1.5, "ci"),
    (_ci(r"^(wondering|not sure)\s+(whether|if)\b|\b(should i|do we need|can we use|what is the best way to)\b"), -1.5, "ci"),
    (_ci(r"^\s*(status|update)\s*[:\-]|\b(nothing to report|all systems (operational|nominal|green)|everything (is fine|looks good)|just a (quick )?(update|check[- ]?in))\b"), -1.5, "ci"),
    (_ci(r"\bremember to\b"), -1.5, "ci"),
    # Hedge stacking (needs two separate matches) handled inline below.
    (_ci(r"\bi\s+(have|got|'ve got)\s+(a\s+)?(meeting|standup|call|sync|1:1|appointment)\b"), -1.5, "ci"),
    (_ci(r"^(hi|hello|hey)\s+(team|all|everyone|folks)\b|\bhope (everyone|you all|y'all)\s+(is|are)\s+(doing\s+)?(well|great|good)\b"), -1.5, "ci"),
    (_ci(r"\b(side note|off[- ]topic|btw|by the way|fun fact)\b"), -1.5, "ci"),
    (_ci(r"\b(the\s+)?(user|customer|client)\s+(probably|likely|maybe|presumably|might have)\b"), -1.5, "ci"),
    (_ci(r"\baccording to (the |our )?(\w+\s+)?(docs|documentation|spec|specification|manual|readme)\b"), -1.5, "ci"),
    (_ci(r"\breminds me of\s+(that one |the one |a |an |that |this )?(episode|movie|show|scene|chapter|moment|time)\b"), -1.5, "ci"),
    (_ci(r"\bi\s+(am|'m)\s+(very|highly|super|really|quite|extremely|absolutely)?\s*(confident|sure|certain|positive)\b"), -1.5, "ci"),
    (_ci(r"\bas requested\b"), -1.5, "ci"),
    (_ci(r"^\s*yes,?\s+(that|this)\s+(approach|plan|idea|sounds|works|is)\b|\bwe should definitely\b"), -1.5, "ci"),
    (_ci(r"\b(one of my|my)\s+(best|finest|cleanest|favorite|favourite)\s+(implementation|implementations|work|code|solution|solutions|design|designs)\b|\bin my opinion\b"), -1.5, "ci"),
    # Vague urgency (stack rule) handled inline below.
    (_ci(r"^\s*(total|summary|stats|counts|metrics)\s*[:\-]"), -1.5, "ci"),
    # Imperative-only-short handled inline below (length + verb + no-qualifier).
    (_ci(r"^wait,?\s+actually\b|\blet me\s+(think|reconsider|re-?analyze)\s+(again|that|this)\b|\blet me reconsider\b"), -1.5, "ci"),
]

# Inline-rule patterns (compiled here, applied in Score-Actionability).
_NAMED_PERSON_B = _cs(r"\b([A-Z][a-z]{1,15})\s+(prefers?|likes?|hates?|loves?|wants?|wishes|thinks|feels|believes|said|told|emailed|complained|asked\s+for)\b")
_HEDGE_GROUP_1 = _ci(r"\b(might|may|could|perhaps)\b")
_HEDGE_GROUP_2 = _ci(r"\b(possibly|maybe|probably|likely)\b")
_URGENCY_ADVERB = _ci(r"\b(urgent|urgently)\b")
_URGENCY_SOFTENER = _ci(r"\b(important|critical|as soon as possible|asap)\b")
_IMPERATIVE_VERB = _cs(r"^(Run|Click|Open|Close|Update|Delete|Save|Build|Deploy|Push|Pull|Execute|Launch|Restart|Reload|Refresh|Type|Press)\b")
_IMPERATIVE_QUALIFIER = _ci(r"\b(if|when|because|unless|always|never|prefer|since|so that)\b")

_CONTRADICTION_HAS_BOTH = _ci(r"\balways\b.*\bnever\b|\bnever\b.*\balways\b")


# ---------------------------------------------------------------------------
# Scoring dimensions.
# ---------------------------------------------------------------------------

def score_reusability(text: str) -> float:
    hits = sum(1 for p in _REUSE_NEG if p.search(text))
    if hits == 0:
        return 0.3
    if hits == 1:
        return -0.3
    return -1.0


def _contradiction_phrase(lc_text: str, marker: str) -> str:
    m = re.search(rf"\b{marker}\b\s+([a-z0-9_/'-]+(?:\s+[a-z0-9_/'-]+){{0,5}})", lc_text)
    if not m:
        return ""
    words = [w for w in m.group(1).split() if len(w) > 1 and w not in CONTRADICTION_STOPWORDS]
    return " ".join(words[:2]).strip()


def _is_contradiction(text: str) -> bool:
    lc = text.lower()
    if not (re.search(r"\balways\b", lc) and re.search(r"\bnever\b", lc)):
        return False
    a = _contradiction_phrase(lc, "always")
    n = _contradiction_phrase(lc, "never")
    return bool(a) and a == n


def score_atomicity(text: str) -> float:
    score = 0.3
    if len(text) > 240:
        score -= 0.5
    if _is_contradiction(text):
        score -= 1.5
    return score


def score_novelty(
    text: str,
    store_claims: dict | None = None,
    recalled_claims: dict | None = None,
) -> tuple[float, str, str]:
    """Iter-10 + iter-11: contradiction-against-store, then feedback-loop.

    Returns (score, contradiction_anchor_id, feedback_loop_id). At most one
    of the two ids is set (first match wins). Neutral (0.0, "", "") when
    neither set is loaded -- preserves the existing labeled-fixture baseline.

    Rules:
      - contradiction-against-store: same subject (>= 2 shared tokens)
        AND opposite polarity vs any store anchor -> -2.0.
      - feedback-loop (iter 11): same subject (>= 4 shared tokens) AND
        same polarity vs any recalled-session item -> -2.0. Higher overlap
        bar because we want real redundancy, not topic similarity.
    """
    if not store_claims and not recalled_claims:
        return 0.0, "", ""
    cand = extract_claim(text)
    if cand is None:
        return 0.0, "", ""
    cand_pol, cand_subj = cand
    if store_claims:
        for anchor_id, (a_pol, a_subj) in store_claims.items():
            if a_pol == cand_pol:
                continue
            if len(cand_subj & a_subj) >= 2:
                return -2.0, anchor_id, ""
    if recalled_claims:
        for recall_id, (r_pol, r_subj) in recalled_claims.items():
            if r_pol != cand_pol:
                continue
            if len(cand_subj & r_subj) >= 4:
                return -2.0, "", recall_id
    return 0.0, "", ""


def extract_claim(text: str) -> tuple[str, set[str]] | None:
    lc = text.lower()
    for pattern, polarity in _CLAIM_TAIL_PATTERNS:
        m = pattern.search(lc)
        if not m:
            continue
        tail = m.group(1)
        tokens = _CLAIM_TOKEN_RE.findall(tail)
        subject = {t for t in tokens if len(t) > 1 and t not in CLAIM_STOPWORDS}
        if not subject:
            return None
        return polarity, subject
    return None


def load_store_claims(path: str) -> dict[str, tuple[str, set[str]]]:
    claims: dict[str, tuple[str, set[str]]] = {}
    if not path:
        return claims
    p = Path(path)
    if not p.exists():
        print(f"Store fixture not found: {path}", file=sys.stderr)
        sys.exit(2)
    for raw in p.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            print(f"Malformed store JSONL line: {line}", file=sys.stderr)
            sys.exit(2)
        c = extract_claim(rec.get("text", ""))
        if c is not None:
            claims[rec.get("id", "")] = c
    return claims


def score_actionability(text: str) -> float:
    score = 0.0
    lc = text.lower()

    for verb in ACTIONABLE_VERBS:
        if re.search(rf"\b{verb}\b", lc):
            score += 0.25
    for filler in VAGUE_FILLERS:
        if re.search(rf"\b{re.escape(filler)}\b", lc):
            score -= 0.5

    for pattern, penalty, mode in _ACTIONABILITY_RULES:
        target = text if mode == "cs" else lc
        if pattern.search(target):
            score += penalty

    # Named-person Pattern B (with tech-allowlist check).
    m = _NAMED_PERSON_B.search(text)
    if m and m.group(1) not in TECH_PROPER_NOUNS:
        score -= 1.5

    # Hedge stacking (iter 7): both groups must hit.
    if _HEDGE_GROUP_1.search(lc) and _HEDGE_GROUP_2.search(lc):
        score -= 1.5

    # Vague urgency (iter 8): adverb + softener.
    if _URGENCY_ADVERB.search(lc) and _URGENCY_SOFTENER.search(lc):
        score -= 1.5

    # Imperative-only-short (iter 8): length + bare verb + no qualifier.
    if (
        len(text) < 80
        and _IMPERATIVE_VERB.search(text)
        and not _IMPERATIVE_QUALIFIER.search(lc)
    ):
        score -= 1.5

    # Cap.
    if score > 1.0:
        score = 1.0
    if score < -1.0:
        score = -1.0
    return score


@dataclass
class ItemScore:
    reusability: float
    atomicity: float
    novelty: float
    actionability: float
    total: float
    decision: str
    reason: str


def score_memory(text: str, store_claims: dict | None = None, recalled_claims: dict | None = None) -> ItemScore:
    r = score_reusability(text)
    a = score_atomicity(text)
    n, anchor, feedback = score_novelty(text, store_claims, recalled_claims)
    c = score_actionability(text)
    total = r + a + n + c
    decision = "keep" if total > 0 else "reject"
    reasons: list[str] = []
    if r < 0:
        reasons.append(f"reusability={_fmt(r)}")
    if a < 0:
        reasons.append(f"atomicity={_fmt(a)}")
    if n < 0:
        if anchor:
            reasons.append(f"novelty={_fmt(n)} (contradicts-store={anchor})")
        elif feedback:
            reasons.append(f"novelty={_fmt(n)} (feedback-loop={feedback})")
        else:
            reasons.append(f"novelty={_fmt(n)}")
    if c < 0:
        reasons.append(f"actionability={_fmt(c)}")
    return ItemScore(r, a, n, c, total, decision, "; ".join(reasons))


def _fmt(v: float) -> str:
    """Match PowerShell's compact numeric formatting (no trailing zeros)."""
    s = f"{v:.10g}"
    return s


# ---------------------------------------------------------------------------
# Fixture I/O.
# ---------------------------------------------------------------------------

def _read_fixture(path: Path) -> list[dict]:
    if not path.exists():
        print(f"Fixture not found: {path}", file=sys.stderr)
        sys.exit(2)
    items: list[dict] = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        try:
            items.append(json.loads(line))
        except json.JSONDecodeError:
            print(f"Malformed JSONL line: {line}", file=sys.stderr)
            sys.exit(2)
    return items


# ---------------------------------------------------------------------------
# Modes.
# ---------------------------------------------------------------------------

def _labeled_summary(items: list[dict], verbose: bool, fail_under: int, store_claims: dict | None = None, recalled_claims: dict | None = None) -> int:
    tp = fp = tn = fn = 0
    detailed: list[tuple[str, str, str, str, float, str, str]] = []

    for rec in items:
        s = score_memory(rec["text"], store_claims, recalled_claims)
        label = rec.get("label", "")
        matched = s.decision == label
        if label == "keep" and s.decision == "keep":
            tp += 1
        elif label == "reject" and s.decision == "keep":
            fp += 1
        elif label == "reject" and s.decision == "reject":
            tn += 1
        elif label == "keep" and s.decision == "reject":
            fn += 1
        detailed.append((
            rec.get("id", ""),
            label,
            s.decision,
            "ok" if matched else "MISS",
            round(s.total, 2),
            rec.get("category", ""),
            s.reason,
        ))

    total = tp + fp + tn + fn
    correct = tp + tn
    accuracy = round(100.0 * correct / total, 1) if total else 0.0
    junk_recall = round(100.0 * tn / (tn + fp), 1) if (tn + fp) else 0.0
    good_recall = round(100.0 * tp / (tp + fn), 1) if (tp + fn) else 0.0

    if verbose:
        print(f"{'id':<14} {'label':<7} {'decision':<8} {'match':<5} {'total':>6} category / reason")
        for row in detailed:
            print(f"{row[0]:<14} {row[1]:<7} {row[2]:<8} {row[3]:<5} {row[4]:>6} {row[5]} {row[6]}")

    print()
    print("Admission-gate baseline (Python port)")
    print(f"  fixture       : {args_fixture_repr()}")
    print(f"  total         : {total}")
    print(f"  accuracy      : {_pct(accuracy)}%   (random baseline: 50.0%)")
    print(f"  junk recall   : {_pct(junk_recall)}%   (Wave 3 exit: >= 80%)")
    print(f"  good recall   : {_pct(good_recall)}%   (Wave 3 exit: >= 80%)")
    print(f"  confusion     : TP={tp}  TN={tn}  FP={fp}  FN={fn}")
    print()

    if fail_under > 0 and accuracy < fail_under:
        print(f"Accuracy {accuracy}% below required {fail_under}%", file=sys.stderr)
        return 3
    return 0


def _pct(v: float) -> str:
    # Mirror PS "$accuracy%" formatting: integers as int, fractions trimmed.
    if v == int(v):
        return str(int(v))
    return f"{v:g}"


def _unlabeled_summary(items: list[dict], show_worst: int, store_claims: dict | None = None, recalled_claims: dict | None = None) -> int:
    scored = []
    for rec in items:
        s = score_memory(rec["text"], store_claims, recalled_claims)
        scored.append({
            "id": rec.get("id", ""),
            "source": rec.get("source", ""),
            "decision": s.decision,
            "total": round(s.total, 2),
            "reason": s.reason,
            "text": rec.get("text", ""),
        })

    n = len(scored)
    keep = sum(1 for x in scored if x["decision"] == "keep")
    reject = n - keep
    totals = [x["total"] for x in scored]
    mean = round(sum(totals) / n, 2) if n else 0.0
    mn = min(totals) if n else 0.0
    mx = max(totals) if n else 0.0
    bins = {"lt -1": 0, "-1..0": 0, "0..1": 0, "1..2": 0, "gt 2": 0}
    for t in totals:
        if t < -1:
            bins["lt -1"] += 1
        elif t < 0:
            bins["-1..0"] += 1
        elif t < 1:
            bins["0..1"] += 1
        elif t < 2:
            bins["1..2"] += 1
        else:
            bins["gt 2"] += 1

    print()
    print("Admission-gate UNLABELED corpus run (Python port)")
    print(f"  fixture     : {args_fixture_repr()}")
    print(f"  items       : {n}")
    rate = round(100.0 * reject / max(1, n), 1)
    print(f"  predicted   : keep={keep}   reject={reject}   reject-rate={_pct(rate)}%")
    print(f"  total score : min={mn}  mean={mean}  max={mx}")
    print(f"  distribution: lt -1={bins['lt -1']}  -1..0={bins['-1..0']}  0..1={bins['0..1']}  1..2={bins['1..2']}  gt 2={bins['gt 2']}")
    print()
    print(f"Lowest-scored {show_worst} items (manual review -- would the gate be wrong?)")
    for x in sorted(scored, key=lambda r: r["total"])[:show_worst]:
        snippet = x["text"]
        if len(snippet) > 110:
            snippet = snippet[:107] + "..."
        print(f"  [{x['total']:>5}] {snippet}  <- {x['source']}")
        if x["reason"]:
            print(f"          reason: {x['reason']}")
    print()
    return 0


# ---------------------------------------------------------------------------
# Parity mode: emit one JSON object per item, decisions only. Used by the
# cross-language parity test in CI.
# ---------------------------------------------------------------------------

def _parity_dump(items: list[dict], store_claims: dict | None = None, recalled_claims: dict | None = None) -> int:
    for rec in items:
        s = score_memory(rec["text"], store_claims, recalled_claims)
        print(json.dumps({
            "id": rec.get("id", ""),
            "decision": s.decision,
            "total": round(s.total, 2),
        }))
    return 0


# ---------------------------------------------------------------------------
# CLI.
# ---------------------------------------------------------------------------

_args_fixture = ""  # filled in main(); used by summary printers for the header.


def args_fixture_repr() -> str:
    return _args_fixture


def main() -> int:
    global _args_fixture
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "--fixture",
        default="admission-gate/fixtures/memories-v4.jsonl",
        help="Path to JSONL fixture (default: %(default)s).",
    )
    parser.add_argument("--verbose", action="store_true", help="Print per-item table.")
    parser.add_argument("--fail-under", type=int, default=0, help="Exit 3 if accuracy < N%%.")
    parser.add_argument("--unlabeled", action="store_true", help="Unlabeled real-corpus mode.")
    parser.add_argument("--show-worst", type=int, default=15, help="Unlabeled: how many low-scored items to show.")
    parser.add_argument("--parity", action="store_true", help="Emit per-item JSON {id,decision,total} for cross-language parity tests.")
    parser.add_argument("--store", default="", help="Path to anchor JSONL ({id,text}). Enables contradiction-against-store check.")
    parser.add_argument("--recalled", default="", help="Path to recalled-session JSONL ({id,text}). Enables feedback-loop check (iter 11).")
    args = parser.parse_args()

    _args_fixture = args.fixture
    items = _read_fixture(Path(args.fixture))
    store_claims = load_store_claims(args.store)
    recalled_claims = load_store_claims(args.recalled)

    if args.parity:
        return _parity_dump(items, store_claims, recalled_claims)
    if args.unlabeled:
        return _unlabeled_summary(items, args.show_worst, store_claims, recalled_claims)
    return _labeled_summary(items, args.verbose, args.fail_under, store_claims, recalled_claims)


if __name__ == "__main__":
    sys.exit(main())
