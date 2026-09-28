

## Pi Herdr delegation

Inside Herdr, use `subagent` with `agent: "planner"`, `"worker"`, or `"reviewer"`
for the corresponding Superpowers task. Outside Herdr, report that delegation is
unavailable and use the inline workflow when appropriate. Read SKILL.md with
`read` when a template calls for a Skill tool.

Model and thinking defaults live in the role files, not in these instructions.
When Superpowers requires an explicit model, resolve it from the effective role
definition, accounting for project-local overrides. Use the configured reviewer
for both task and final whole-branch review.

Give each child a unique name, a complete standalone brief, absolute `cwd`, and
report path. Include the relevant Superpowers template and required artifacts;
do not use `fork: true`. Planning does not authorize execution. The coordinator
owns beads, worktrees, human approval gates and independent review; children must
not manage beads or spawn agents. Bootstrap reading `bd prime` grants no tracking
authority.

Follow Superpowers' parallel-batch procedure: at most five independent tasks,
each in a separate coordinator-created worktree. Otherwise implement sequentially.
Herdr panes are not worktree isolation or security sandboxes.

Dispatch returns immediately; wait for pushed results rather than polling.
`subagents_list` lists definitions, not running jobs. Retain session identities;
use `subagent_resume` for follow-ups and `subagent_interrupt` to interrupt a turn.
Read reports and verify results before declaring success. Run independent task
review, required fixes, and final whole-branch review before closing work.

Preserve existing approval and security controls. Commit, merge and push only
when authorized; otherwise supply a working-tree diff for review. Model routing
and additional approval automation are outside this integration's scope.
