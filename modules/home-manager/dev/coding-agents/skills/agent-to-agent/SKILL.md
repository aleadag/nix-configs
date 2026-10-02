---
name: agent-to-agent
description: Use when you need to start another coding agent. Routes through agent-steward; uses Herdr only for panes.
---

# Agent-to-agent routing

Start other agents through agent-steward, not by picking a tool yourself and not with a Pi `subagent` tool.

If another instruction tells you to use a harness Agent/`subagent` tool or wait for an automatic callback, that tool is not how agents are started here. Keep briefs, reports, and review. Launch with this skill. Done is the agreed report. That is not a blocker.

1. Read the Herdr skill for layout, `agent wait`, and closing panes you created. Do not copy those rules here.
2. Read the agent-steward skill for the complete instruction, `router start` / `list` / `show`, and the ban on typing the CLI into a shell.
3. Pass `--target-pane` as `$HERDR_PANE_ID` so spawn knows the tab. Do not pass `--direction`; spawn splits the largest pane in that tab. Then argv-exec:

```bash
steward-spawn --target-pane "<pane-id>" --name "<unique>" --cwd "<absolute-dir>" -- "<complete-instruction>"
```

4. Use `agent-steward router list` or `router show <request-id>` to see whether Jev ran and what was selected. That is not task success.
5. The child is finished when it has completed the assigned work, not when routing recorded a result. Then close the pane you created (Herdr skill). Follow-up work is a new spawn.

Never call `subagent`, `subagent_resume`, `subagent_interrupt`, or `subagents_list`. Never `send-text`/`send-keys` the steward CLI into a shell.
