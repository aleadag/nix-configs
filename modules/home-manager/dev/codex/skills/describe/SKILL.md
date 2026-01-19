---
name: describe
description: Generate a conventional commit description with emoji from jj diff and apply it with jj describe
---

# Jujutsu Describe

Use this skill when the user asks to describe changes (like Claude Code /describe).

## Workflow

1. Gather context with Jujutsu directly:
   - `jj status`
   - `jj diff -r [REVSET] --git`
2. Review the diff and decide whether to split the change. If multiple unrelated concerns are present, ask the user to split first.
3. Generate a conventional commit message with emoji, format: `<emoji> <type>: <imperative description>`
4. Apply it: `jj describe -m "message" [REVSET]`

## Commit Types

- ✨ feat: new feature
- 🐛 fix: bug fix
- 📝 docs: documentation
- ♻️ refactor: refactoring
- ⚡️ perf: performance
- ✅ test: tests
- 🔧 chore: tooling/config
- 🚨 fix: compiler/linter warnings
- 🗑️ revert: revert change

## Notes

- Keep the first line under 72 chars.
- Prefer present tense, imperative mood.
- If splitting is needed, guide the user through manual `jj new` + `jj squash --from @- <file_pattern>`.
