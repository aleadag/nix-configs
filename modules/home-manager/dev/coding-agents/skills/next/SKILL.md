---
name: next
description: Execute a production-quality implementation workflow: research first, create a plan, implement the change, and validate it before finishing.
---

# Next

Use this skill for normal feature work, refactors, and bug fixes when the user wants implementation rather than advice.

## Required Opening

Start with:

`Let me research the codebase and create a plan before implementing.`

If the task is structurally ambiguous or high risk, also say:

`Let me ultrathink about this architecture.`

## Workflow

1. Research the existing code and patterns first.
2. Produce a concrete plan based on what you found.
3. Implement the change directly.
4. Validate with formatting, linting, and tests that fit the repository and the touched code.

## Implementation Rules

- Prefer explicit, direct solutions over clever abstractions.
- Delete replaced code instead of introducing parallel versions.
- Keep functions small and focused.
- Add tests for non-trivial logic.
- Fix validation failures before declaring completion.

## Validation

Run the relevant formatter, linter, and test commands before finishing. If a command cannot run because of environment limits, state the exact blocker.
