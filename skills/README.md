# Skills Layer

Skills are outcome-focused execution packs. They sit between broad domain playbooks and incident-level lessons.

Use skills when you need repeatable execution for a known job (deploy triage, PR review, API rollout), not open-ended exploration.

## Structure

- `skills/templates/skill-template.md` - authoring template for new skills
- `skills/templates/workflow-command-template.md` - template for multi-skill workflow commands
- `skills/templates/router-template.md` - template for plain-English intent routing
- `skills/general/...` - cross-domain skills
- `skills/salesforce/...` - Salesforce-specific skills
- `skills/mulesoft/...` - MuleSoft-specific skills

## What belongs in a skill

1. Clear outcome and entry conditions
2. Required inputs and prerequisites
3. Ordered steps
4. Verification commands and success criteria
5. Common failure modes and fallback path
6. Capture rule for adding reusable lessons after execution

## Skills vs commands

- A **skill** does one thing well.
- A **workflow command** chains multiple skills to finish a complete job with approval gates.
- A **router** maps plain-English requests to the right workflow command.

## Concrete examples

- Salesforce command example: `skills/salesforce/commands/deploy-incident-workflow.md`
- Salesforce router example: `skills/salesforce/router/salesforce-router.md`

## Promotion rules

Promote a pattern from a lesson into a skill only if:

1. It has been reused successfully in at least two sessions.
2. It includes at least one verification command.
3. It reduces retries or handoff confusion.
