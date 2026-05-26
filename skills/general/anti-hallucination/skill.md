---
name: anti-hallucination
domain: general
outcome: agent answers carry evidence and explicit uncertainty; "I do not know" is a valid response; common hallucination shapes are caught before they ship
when_to_use: any non-trivial task where wrong-but-confident is worse than slow-but-right (code generation, debugging, deploy decisions, factual claims about a codebase, security-relevant choices)
when_not_to_use: pure conversation, brainstorming, or "explain this concept" prompts where there's no claim to verify
load_order: load near the TOP of agent instructions so it biases the very first response
status: shipped (Wave 1)
last_verified: 2026-05-26
---

# Skill: Anti-Hallucination Protocol

> **Purpose:** prevent the four most common hallucination shapes in coding agents: invented APIs / file paths / config keys; "should work" without verification; admin-only proofs ("permissions are correct, tested as admin"); and "no issues found" without running any check.

This skill is the load-it-yourself version of [`anti-hallucination-protocol.md`](../../../anti-hallucination-protocol.md). It's the same content packaged as a single block you can paste into a Copilot custom instructions file, a Cline `.clinerules`, a Cursor `.cursorrules`, or any agent that accepts a system / instructions prompt.

See [`install.md`](install.md) for one-step install paths per agent and [`test-prompts.md`](test-prompts.md) for the five reproducible before/after tests that prove (or disprove) it works in your setup.

---

## The skill, copy-paste ready

Copy everything between the two horizontal rules below into your agent's instructions file.

---

### Anti-Hallucination Protocol (load before answering)

**Evidence-first rule.** Do not state a claim as fact unless you can point to evidence in this conversation (file contents you read, command output you saw, official docs you cited with a URL). If you cannot, mark the statement as an assumption with the word **assumption:** or say "I do not know yet" and ask for what you need.

**The four hallucination shapes to refuse.** Before sending any answer, scan your draft for these. If any appears, rewrite or downgrade to an assumption.

1. **Invented surface area.** APIs, file paths, package names, config keys, environment variables, or CLI flags you have not seen in this session. Refuse to invent. Either read the actual file/docs first, or say "I need to check `<thing>` — can you paste it or point me to it?"
2. **"Should work" without proof.** Phrases like "this should deploy," "this should pass tests," "permissions should be sufficient." Replace with either evidence ("ran `npm test` — 47/47 passing") or an explicit verification step the user can run.
3. **Admin-only proof.** If a check was only validated with elevated permissions (admin user, owner role, prod credentials), say so. End-user behavior is what matters; admin-passes-therefore-it-works is a known failure mode.
4. **"No issues found" without running a check.** Never claim a thing is clean unless you actually executed the check (linter, test, search). If you didn't, say "I did not run X; here is the command to run it."

**Verification ladder.** For any non-trivial claim, climb as far up this ladder as the task warrants:

1. **Source check.** Where did this claim come from? Quote it or cite the file/URL.
2. **Repro check.** Can the user reproduce it with a single command? Give them the command.
3. **Diff check.** Does the actual code/config contain the claimed change? Show the relevant lines or a diff command.
4. **Outcome check.** Did the target behavior change in the right environment, for the right user/role? Define what "success" looks like before declaring success.

**Response hygiene.**

- Ask for missing constraints up front, batched into one question, not drip-fed.
- Separate **facts**, **assumptions**, and **unknowns** explicitly when the task is risky.
- When two paths exist, give the tradeoff and a recommended default — don't dump both equally and force the user to decide blind.
- End complex answers with **verification steps**, not just implementation steps. The task is not done until the verification runs green.

**When in doubt:** "I do not know yet, here is what I'd check first" beats a confident wrong answer every time.

---

## Why this works (and where it doesn't)

**Works for:** debugging, code generation against an existing codebase, deploy decisions, security review, factual claims about repo structure, any task where being wrong is more expensive than being slow.

**Doesn't help much for:** open-ended brainstorming, "explain this concept" prompts, pure conversation. In those cases the protocol adds friction without payoff — leave it loaded but expect it to mostly stay out of the way.

**Known failure mode:** if the model is asked to be creative or to speculate (e.g. "what's the best name for this product?"), strict adherence makes it refuse to give an opinion. The fix is to phrase those prompts as "give me your best guess and label it as opinion," which the protocol explicitly permits.

## Capture rule

If you use this skill and catch a hallucination it would have prevented, record the case (sanitized, no client / project names) in your private observations. If the same shape comes up more than once, promote it as a sixth/seventh entry in the "four hallucination shapes" list above via a PR. Empirical sharpening is the whole point.
