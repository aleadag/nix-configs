---
name: describe
description: Review a jj changeset, decide whether it should be split, and write an accurate emoji conventional commit description with jj describe.
---

# Describe

Use this skill when the user wants help describing a `jj` change or curating commit messages.

## Workflow

1. Inspect the requested revset, defaulting to `@` when the user does not specify one.
2. Read the diff and status before writing a message.
3. Decide whether the change is atomic. If not, explain the split you recommend and help perform it before describing.
4. Write a concise conventional commit subject with an emoji prefix.
5. Apply it with `jj describe`.

## Message Rules

- Format: `<emoji> <type>: <imperative summary>`
- Keep the summary specific and short.
- Match the message to the actual diff, not the user’s intent alone.

## Common Types

- `✨ feat`
- `🐛 fix`
- `📝 docs`
- `💄 style`
- `♻️ refactor`
- `⚡️ perf`
- `✅ test`
- `🔧 chore`
- `🚀 ci`

## Splitting Guidance

Split changes when they mix unrelated concerns, user-facing behavior with tooling churn, or large refactors with drive-by fixes. Prefer separate `jj` changesets over one overloaded description.
