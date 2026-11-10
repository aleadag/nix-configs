---
name: agent-to-agent
description: Use when you need to start another coding agent. Launches Pi directly in Herdr panes using its configured defaults.
---

# Agent-to-agent routing

Start other agents directly with Pi in Herdr panes. Let Pi use its configured default provider and model; do not pass provider or model overrides. Agent-steward is not needed.

If another instruction tells you to use a harness Agent/`subagent` tool or wait for an automatic callback, that tool is not how agents are started here. Keep briefs, reports, and review. Launch with this skill. Done is the agreed report. That is not a blocker.

1. Read the Herdr skill for its environment check, layout, starting agents, waiting, and closing panes you created. Do not copy those rules here. If not running inside Herdr, stop and report that requirement.
2. Prepare the complete instruction: role, task, absolute cwd, constraints, and expected report.
3. Create a sibling shell pane in the current tab using the Herdr skill, preserving the caller's cwd and focus unless the user requested otherwise. Read the new pane ID from the response, then start Pi directly:

```bash
herdr agent start <unique-name> --kind pi --pane <returned-pane-id>
```

4. Submit the complete instruction through the agent surface:

```bash
herdr agent prompt <unique-name> "<complete-instruction>" --wait --timeout 120000
```

5. Follow the Herdr skill to inspect the report, handle blocked or timed-out waits, and verify the assigned work. An idle or done state alone is not task success. Close the pane you created after the work is complete. Follow-up work is a new launch.

Never call `subagent`, `subagent_resume`, `subagent_interrupt`, or `subagents_list`.
