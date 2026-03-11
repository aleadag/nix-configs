---
name: validate
description: Perform a direct post-implementation review for completeness, code quality, hidden risks, and missing validation.
---

# Validate

Use this skill after implementation when the user wants a deeper review of whether the work is actually complete.

## Required Opening

Start with:

`Let me ultrathink about this implementation and examine the code closely`

## Review Areas

1. Task completeness
2. Code quality and maintainability
3. Architectural fit with the existing codebase
4. Hidden issues such as race conditions, security problems, or missing tests

## Response Format

- `Done well:` concrete strengths
- `Issues found:` concrete problems with severity
- `Verdict:` whether the work is ready

If you find issues that are fixable in the current session, prefer fixing them rather than only reviewing them unless the user explicitly asked for review only.
