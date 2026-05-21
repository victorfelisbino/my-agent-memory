# Common Gotchas & Lessons Learned

## Salesforce Deployment

- **Gearset _-_qa branches**: Commits left only on the _-_qa head are silently dropped when promoting to STG/Prod. Cherry-pick bot commits back to the base branch.
- **Profile deploy hangs**: Use --metadata "Profile:Admin" --async --wait 120
- **Reports/Dashboards excluded**: They're in .forceignore to keep CLI fast. Deploy individually with --metadata
- **Large repo (326k files)**: Must set SF_DISABLE_SOURCE_MEMBER_POLLING=true or deploys hang with EEXIT:130
- **LWC Jest required**: Cannot deploy LWC to dev2 or PR to qa without passing __tests__/<name>.test.js
- **`sf project deploy start` rollback default**: `rollbackOnError=true` is the default. When any component fails, the "successful" components from the same call are rolled back too. Pass `--ignore-errors` only when partial deploys are intentional, and always re-read the final deploy report before assuming anything landed.

## Salesforce Development

- **Profiles vs Permission Sets**: Always use Permission Sets for new permissions (easier to version control)
- **Lookup field limit**: Each object max 40 lookup fields. Delete cold lookups permanently from "Deleted Fields" table or they still count
- **Hardcoded IDs**: Always use getRecordTypeInfosByDeveloperName() instead
- **New Process Builders/Workflow Rules**: Not allowed - build a Flow instead
- **No @isTest(SeeAllData=true)** without written justification
- **PII in logs**: Never System.debug(user.email) or commit credentials
- **Org-specific LWC component names**: Standard-looking names like `sfa:recordDetailDuplicatesPanel` may not exist in your org; the equivalent here is `runtime_sales_merge:mergeCandidatesPreviewCard`. Verify a component name against the target org's actual layout/page metadata before referencing it in code or deploys.

## Code Review Red Flags

- SOQL/DML in loops (auto PR-fail)
- No bulkification pattern (Maps/Sets for batch operations)
- Missing WITH SECURITY_ENFORCED on user-facing queries
- New Aura components (should be LWC)
- Component duplication (check registry first)

## Troubleshooting

- **Copilot Chat is slow**: Need to set SF_DISABLE_SOURCE_MEMBER_POLLING env vars. Run /optimize-workspace prompt.
- **Deploy hangs with no output**: Likely a source tracking conflict. Use --ignore-conflicts flag.
- **"UNABLE_TO_LOCK_ROW"**: Concurrent transaction issue. Add @future or use batch apex.
- **"MALFORMED_ID"**: Wrong record type ID or wrong org. Double-check getRecordTypeInfosByDeveloperName()
- **"0 parsed and 0 failed" is not success**: A clean-looking result often means the upstream SOQL/query returned zero rows, not that the job worked. Always log input row count alongside parsed/failed counts and fail loudly when input is zero unexpectedly.

## Recurring Branch and Pipeline Issues (from chat history)

- **"Did it deploy?" confusion**: Track status in three places every time: git branch push status, Gearset PR status, and target org deploy result. One being green does not imply the other two are green.
- **_-_qa vs base branch drift**: If a fix lands only on the _-_qa head branch, promotion can miss it. Always back-propagate accepted suggestion commits to the PR base branch.
- **main_-_stg validation failures**: Repeated failures often come from stale profile references and profileActionOverrides in CustomApplication metadata. Audit profile refs before retriggering.
- **Field visible to admin but not user**: Usually not layout-only. Validate all three: field-level security, permission set/profile assignment, and record page/layout assignment for the affected persona.
- **"No changes in PR" surprise**: Usually means the fix is already in target or landed on a sibling branch. Use branch diff checks before creating another PR.

## Decision Guardrails (stop repeat mistakes)

- **Never call a fix done until all 3 are true**: branch pushed, PR reflects diff, org deploy succeeded.
- **Never trust admin-only UI validation**: verify with affected user persona before closing defect.
- **Never retrigger blindly after failure**: capture first failing component and fix root cause before rerun.
- **Never assume branch health from one environment**: validate path for dev2 -> qa -> stg dry-run -> prod dry-run when applicable.
- **Never open a new PR before diff check**: confirm the delta exists against target to avoid empty/no-op PR cycles.
- **Never trust a tool's "successfully edited / applied" message alone**: multi-edit and apply tools have reported success while individual edits silently failed. Re-read the file or check `git diff` before declaring the change done.

## Done Criteria for defect closure

- Reproduced original issue once.
- Confirmed fix in target org as intended user profile/permission set.
- Confirmed metadata is on the promoting branch (not only on _-_qa head).
- Logged deploy id(s) and PR/commit evidence.
