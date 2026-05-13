# Common Gotchas & Lessons Learned

## Salesforce Deployment

- **Gearset _-_qa branches**: Commits left only on the _-_qa head are silently dropped when promoting to STG/Prod. Cherry-pick bot commits back to the base branch.
- **Profile deploy hangs**: Use --metadata "Profile:Admin" --async --wait 120
- **Reports/Dashboards excluded**: They're in .forceignore to keep CLI fast. Deploy individually with --metadata
- **Large repo (326k files)**: Must set SF_DISABLE_SOURCE_MEMBER_POLLING=true or deploys hang with EEXIT:130
- **LWC Jest required**: Cannot deploy LWC to dev2 or PR to qa without passing __tests__/<name>.test.js

## Salesforce Development

- **Profiles vs Permission Sets**: Always use Permission Sets for new permissions (easier to version control)
- **Lookup field limit**: Each object max 40 lookup fields. Delete cold lookups permanently from "Deleted Fields" table or they still count
- **Hardcoded IDs**: Always use getRecordTypeInfosByDeveloperName() instead
- **New Process Builders/Workflow Rules**: Not allowed - build a Flow instead
- **No @isTest(SeeAllData=true)** without written justification
- **PII in logs**: Never System.debug(user.email) or commit credentials

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
