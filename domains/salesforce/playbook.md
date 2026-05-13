# Salesforce Playbook

## Start of task

- Confirm org alias and target branch.
- Check branch diff before creating PR.
- Keep deployments reproducible with explicit selectors.

## Frequent risks

- branch drift between base and _-_qa head
- profile cross-reference failures
- layout fixed but missing FLS/perm assignment

## Required evidence before closure

- deploy id report
- PR includes expected metadata diff
- verification as affected user profile
