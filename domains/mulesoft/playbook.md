# MuleSoft Playbook

## Start of task

- Confirm environment (dev/qa/stg/prod) and target app/version.
- Confirm API contract version and expected policies.
- Confirm deployment pipeline path before changes.

## Frequent risks

- environment property mismatch
- policy differences between environments
- connector/auth config drift
- schema or mapping mismatch across systems

## Required evidence before closure

- deployment id or runtime deployment evidence
- successful endpoint smoke test
- log proof for success path and one expected error path
