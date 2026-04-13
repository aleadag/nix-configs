---
name: commit-message
description: Review a change, decide whether it should be split, and write an accurate emoji conventional commit message that matches the actual diff.
---

# Commit Message

Use this skill when the user wants help writing or curating a commit message, regardless of VCS.

For the final apply step, load exactly one reference:

- Git: [references/git.md](references/git.md)
- Jujutsu: [references/jj.md](references/jj.md)

## Workflow

1. Inspect the requested change scope before writing a message.
2. Read the diff and status for that scope.
3. Decide whether the change is atomic. If not, explain the split you recommend before writing a final message.
4. Write a concise conventional commit subject with an emoji prefix.
5. Use the matching VCS reference to apply the final message.

## Message Rules

- Format: `<emoji> <type>: <imperative summary>`
- Keep the summary specific and short.
- Match the message to the actual diff, not the user's intent alone.

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

Split changes when they mix unrelated concerns, user-facing behavior with tooling churn, or large refactors with drive-by fixes. Prefer smaller, reviewable commits or changesets over one overloaded message.
