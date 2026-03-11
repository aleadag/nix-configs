---
name: check
description: Fix lint, test, build, and formatting failures until the repository is green. Use when the user asks to check, validate, clean up, or make CI pass.
---

# Check

Use this skill when the user wants code quality verification that ends in fixes, not a report.

## Workflow

1. Identify the relevant validation commands for the repository.
2. Run the checks that matter for the current change.
3. Fix every failure you find.
4. Re-run the checks.
5. Repeat until the relevant checks pass or you are blocked by something external.

## Requirements

- Treat this as a fixing task, not a reporting task.
- Do not stop after listing issues if you can fix them.
- Prefer targeted validation first, then broader validation before finishing.
- If a hook, formatter, linter, or test fails, fix that result before moving on.
- If a failure is caused by missing credentials, network restrictions, or sandbox limits, say so clearly and continue with every check you can still run.

## Completion

Only conclude once you have either:

- made the relevant checks pass, or
- identified a concrete external blocker you cannot resolve locally.
