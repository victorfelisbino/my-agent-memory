# Salesforce Debugging Patterns

## Governor Limits

- **SOQL queries**: Max 100 (150 in batch) — use Map<Id, SObject> to batch lookups
- **DML statements**: Max 150 per transaction — bulkify into single List operations  
- **Heap size**: Max 6 MB (12 MB in batch) — avoid large string concatenations
- **Callout time**: Max 120 seconds per request (60 seconds in Apex tests)

## Performance Tips

- **Index missing on Lookup field?** Query slows to crawl. Check Setup > Custom Objects > [Object] > Fields
- **Query analyzer**: Always run SELECT COUNT() first before fetching full records
- **Batch size tuning**: Start with 50-100, increase if heap stays below 50% of limit
- **String concatenation**: Use StringBuilder or single insert/update instead of loop DML

## Debug Logs

1. Setup > Debug Logs > New
2. Add your user + desired timestamp
3. Replay issue  
4. Download logs and search for:
   - FATAL_ERROR = governor limit hit
   - EXCEPTION = error stack trace
   - ENTERING_MANAGED_PKG = third-party code issue

## Common Issues

- UNABLE_TO_LOCK_ROW: Two transactions updating same record. Add @future or batch the update
- MALFORMED_ID: Hardcoded ID doesn't exist or wrong org. Use getRecordTypeInfosByDeveloperName()
- REQUIRED_FIELD_MISSING: Check custom object for required fields before insert/update
- SYSTEM.LIMIT_EXCEPTION: Exceed max 3,000 SOSL results per transaction
- "bad value for restricted picklist field: Task" when adding a custom field to Task: Activity-related custom fields must be created on the `Activity` object (the polymorphic parent), not on `Task` or `Event` directly. The same field then surfaces on both Task and Event.

## Profiling Apex

```apex
Long startTime = System.now().getTime();
// ... code to profile ...
Long elapsed = System.now().getTime() - startTime;
System.debug('Elapsed: ' + elapsed + 'ms');
```

## Testing Limits

```apex
System.debug('Query calls remaining: ' + Limits.getQueryLocalsRemaining());
System.debug('DML rows: ' + Limits.getDmlRows());
System.debug('Heap size: ' + Limits.getHeapSize());
```

## Field visible to admin but not user - triage order

1. Verify field-level security for the exact profile/permission set.
2. Verify permission set assignment for the affected user.
3. Verify layout assignment for the record type and profile.
4. Verify Lightning record page activation by app, profile, and record type.
5. Re-test while logged in as the target user.

## Deploy result truth-check

Treat deployment as successful only when all checks pass:
- SF deploy report says succeeded for the target org.
- Branch contains the fix commit(s).
- PR diff shows expected metadata changes.
