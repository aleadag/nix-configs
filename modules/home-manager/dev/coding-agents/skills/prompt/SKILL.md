---
name: prompt
description: Generate a reusable implementation prompt that embeds the repository's research-plan-implement-validate workflow for another coding agent.
---

# Prompt Synthesizer

Use this skill when the user wants a ready-to-paste prompt for another agent or CLI.

## Output

Return a single markdown code block containing a standalone prompt. Do not add explanation outside the code block unless the user asks for it.

## Prompt Requirements

The generated prompt should instruct the target agent to:

1. research the codebase first,
2. create a plan before editing,
3. implement directly without compatibility cruft,
4. validate with formatting, linting, and tests,
5. report blockers precisely.

## Adaptation Rules

- Integrate the user's task naturally into the prompt.
- Emphasize language- or tool-specific constraints only when relevant.
- Keep the prompt self-contained so it works in a fresh session.
