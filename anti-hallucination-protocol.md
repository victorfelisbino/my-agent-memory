# Anti-Hallucination Protocol

Use this before trusting an answer or closing a task.

## Evidence First Rule

- Do not accept claims without evidence from code, logs, deploy reports, or official docs.
- Mark uncertain statements as assumptions.
- Prefer "I do not know yet" over a guessed answer.

## Verification Ladder

1. Source check: where did this claim come from?
2. Repro check: can we reproduce the claim with a command or test?
3. Diff check: does code/metadata actually contain the claimed change?
4. Outcome check: did target behavior change in the right environment and user context?

## Response hygiene for future chats

- Ask for missing constraints early (env, branch, target org, acceptance criteria).
- Separate facts from assumptions explicitly.
- When multiple paths exist, provide tradeoffs and recommended default.
- End with verification steps, not just implementation steps.

## Hallucination red flags

- "Should be deployed" without deploy id/report.
- "PR includes fix" without actual diff evidence.
- "Permissions are correct" tested only as admin.
- "No issues found" without running checks.
