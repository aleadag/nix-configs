# JJ Apply Flow

Use this reference when the repository uses Jujutsu.

## Workflow

1. Inspect the requested revset, defaulting to `@` when the user does not specify one.
2. If the change should be split, recommend separate `jj` changesets before describing.
3. Apply the final message with `jj describe`.

## JJ Notes

- Match the description to the selected revset, not neighboring changesets.
- Keep the final subject concise enough to fit naturally in `jj log`.
