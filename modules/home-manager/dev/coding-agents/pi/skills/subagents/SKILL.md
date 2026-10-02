---
name: subagents
description: Use when starting a planner, worker, or reviewer from Pi. Pi has no native subagent tool.
---

# Pi subagents

Pi does not provide a `subagent` tool. If another instruction tells you to use a harness Agent/`subagent` tool, follow this skill instead. That is not a blocker.

Named roles live next to this skill:

- planner — `agents/planner.md`
- worker — `agents/worker.md`
- reviewer — `agents/reviewer.md`

To start one:

1. Read the matching role file. Put its effective definition in the complete instruction, with a unique name, absolute cwd, and report path.
2. Follow the `agent-to-agent` skill to route and start. Do not pick the child tool or model yourself.
3. Never call `subagent`, `subagent_resume`, `subagent_interrupt`, or `subagents_list`.

Those role files have `spawning: false`. Do not tell a child to start further agents.
