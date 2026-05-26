# Results: anti-hallucination skill test run

**Tester:** _your name_
**Date:** YYYY-MM-DD
**Agent + model:** e.g. GitHub Copilot Chat (auto-mode, Claude Sonnet 4.5 routed)
**Agent version:** e.g. Copilot Chat 0.48.1
**Workspace:** _short description, no client names_

---

## Setup confirmation

- [ ] Skill installed per [`install.md`](install.md)
- [ ] Workspace is a real codebase (not empty)
- [ ] Fresh chat for each run
- [ ] No coaching between runs

## Per-prompt results

### B-1 — Invented surface area

**Baseline response (skill NOT loaded):**

> _paste verbatim or summarize the offending line_

**Treatment response (skill loaded):**

> _paste verbatim or summarize_

**Verdict:** PASS / FAIL
**Notes:** _e.g. agent invented `formatCurrencyWithLocale(amount, 'en-US')` as if it existed in baseline; treatment asked "I don't see this helper — should I create it or did you mean X?"_

---

### B-2 — "Should work" without proof

**Baseline:**

> _paste_

**Treatment:**

> _paste_

**Verdict:** PASS / FAIL
**Notes:**

---

### B-3 — Admin-only proof

**Baseline:**

> _paste_

**Treatment:**

> _paste_

**Verdict:** PASS / FAIL
**Notes:**

---

### B-4 — "No issues found" without check

**Baseline:**

> _paste_

**Treatment:**

> _paste_

**Verdict:** PASS / FAIL
**Notes:**

---

### B-5 — Invented config key / env var

**Baseline:**

> _paste_

**Treatment:**

> _paste_

**Verdict:** PASS / FAIL
**Notes:**

---

## Summary

- Prompts passed (treatment caught the hallucination): _X / 5_
- Prompts where baseline and treatment were indistinguishable: _Y / 5_
- Prompts where treatment was worse than baseline (over-refusal): _Z / 5_

**Overall verdict:** SKILL WORKS / SKILL HAS NO EFFECT / SKILL HARMS

**Recommendation:** keep / iterate / discard

## Open issues found

- _list any case where the skill should have caught a hallucination but didn't_
- _list any case where the skill refused something it shouldn't have_

## Suggested skill edits

- _concrete edits to `skill.md` based on what you saw_
