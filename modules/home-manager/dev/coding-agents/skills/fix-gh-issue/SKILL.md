---
name: fix-gh-issue
description: Investigate a GitHub issue with gh, plan the fix, implement it in small steps, and verify the result before closing out.
---

# Fix GitHub Issue

Use this skill when the user asks to fix or implement work tracked in a GitHub issue.

## Workflow

1. Read the issue with `gh issue view`.
2. Understand the failing behavior, expected behavior, and acceptance criteria.
3. Research the codebase and nearby history before editing.
4. Write down a concrete implementation plan in a scratchpad if the task is non-trivial.
5. Implement the fix in small, reviewable steps.
6. Run the relevant validation commands.

## Research Checklist

- Search the codebase for affected files and similar patterns.
- Inspect recent history when it can explain intent or regressions.
- Check related issues or PRs when that context is available.

## Implementation Rules

- Prefer a direct fix over compatibility layers.
- Delete superseded code instead of keeping parallel paths.
- Keep commits or jj changesets scoped to logical steps when the work is large.
- Use `gh` for GitHub interactions.

## Completion

Before finishing, confirm what changed, what validation ran, and whether anything remains blocked outside the repository.
