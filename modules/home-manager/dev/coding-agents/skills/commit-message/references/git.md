# Git Apply Flow

Use this reference when the repository uses Git.

## Workflow

1. Inspect the requested Git change scope, defaulting to staged changes when the user does not specify one.
2. If the user is updating the last commit, apply the final message with `git commit --amend -m "<message>"`.
3. Otherwise apply it with `git commit -m "<message>"` after confirming the intended content is staged.

## Git Notes

- Do not invent scope beyond what is staged or explicitly requested.
- If the working tree mixes staged and unstaged changes, make that visible before committing.
- If the change should be split, recommend the split before applying a message.
