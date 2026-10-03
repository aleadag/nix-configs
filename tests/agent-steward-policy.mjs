import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { readFileSync, realpathSync } from "node:fs";
import { join } from "node:path";

const f = JSON.parse(readFileSync(process.argv[2], "utf8"));

assert.doesNotMatch(f.policyNix, /\.internal(?:\/|\b)/, "policy checks must not depend on ignored artifacts");
assert.ok(f.raw && f.bun && f.bunPackage && f.expectedBunVersion, "policy check must use packaged Bun");
assert.equal(realpathSync(join(f.raw, "lib/agent-steward/bun")), realpathSync(f.bunPackage));
const bunVersion = spawnSync(f.bun, ["--version"], { encoding: "utf8", env: { PATH: "" } });
assert.equal(bunVersion.status, 0, bunVersion.stderr);
assert.equal(bunVersion.stdout.trim(), f.expectedBunVersion);
assert.match(f.coordinator, /name: agent-to-agent/);
assert.match(f.coordinator, /steward-spawn --target-pane "<pane-id>" --name "<unique>" --cwd "<absolute-dir>" -- "<complete-instruction>"/);
assert.doesNotMatch(f.coordinator, /--pane\b|--ratio\b/);
assert.match(f.coordinator, /router list/);
assert.match(f.coordinator, /router show <request-id>/);
assert.match(f.coordinator, /Never call `subagent`, `subagent_resume`, `subagent_interrupt`, or `subagents_list`/);
assert.match(f.coordinator, /Never `send-text`\/`send-keys`/);
assert.match(f.coordinator, /close the pane you created/);
assert.match(f.coordinator, /Follow-up work is a new spawn/);
assert.match(f.coordinator, /That is not a blocker/);
assert.doesNotMatch(f.coordinator, /subagent-driven-development/);
// Point at Herdr for wait/close; do not copy idle/done semantics.
assert.doesNotMatch(f.coordinator, /idle.*done|--until/);
assert.match(f.spawn, /router start/);
assert.match(f.spawn, /plugin pane open --plugin agent-steward-launcher/);
assert.doesNotMatch(f.spawn, /--plugin pi-herdr-subagents|send-text|send-keys/);
assert.match(f.subagents, /name: subagents/);
assert.match(f.subagents, /agents\/explore\.md/);
assert.match(f.subagents, /agents\/planner\.md/);
assert.match(f.subagents, /agents\/worker\.md/);
assert.match(f.subagents, /agents\/reviewer\.md/);
assert.match(f.subagents, /Follow the `agent-to-agent` skill/);
assert.match(f.subagents, /Never call `subagent`, `subagent_resume`, `subagent_interrupt`, or `subagents_list`/);
assert.match(f.subagents, /That is not a blocker/);
assert.doesNotMatch(f.subagents, /subagent-driven-development/);
assert.doesNotMatch(f.subagents, /--config|--dry-run|SOPS|TYPESAFE_API_KEY|planned_command\.display/);
assert.doesNotMatch(f.piModule, /HERDR\.md|configDir}\/agents\/planner/);
assert.match(f.piModule, /\.\/skills\/subagents/);
assert.match(f.piModule, /\(pluginSkills \/\/ agentsCfg\.skills\)/);
assert.doesNotMatch(f.piModule, /superpowers\.patch|pi-tools\.md|piPluginSkills|piPlugins/);
assert.match(f.piModule, /context = agentsCfg\.context;/);

assert.ok(f.roles.explore, "the explore role must be supplied");
assert.match(f.roles.explore, /^name: explore$/m);
assert.match(f.roles.explore, /^tools: read,bash$/m);
assert.match(f.roles.explore, /file:line/);
assert.match(f.roles.explore, /codebase only/);
assert.match(f.roles.explore, /Do not modify project files, run beads commands, or spawn other agents/);

for (const text of Object.values(f.roles)) {
  const front = text.split("---")[1];
  assert.doesNotMatch(front, /^(model|thinking):/m);
  for (const line of ["spawning: false", "auto-exit: true", "session-mode: standalone", "system-prompt: append"])
    assert.ok(front.includes(line));
}
assert.match(f.piModule, /defaultModel = "gpt-6\.1-sol"/);
assert.match(f.piModule, /defaultThinkingLevel = "medium"/);
assert.doesNotMatch(f.piModule, /skills\.agent-(?:steward|to-agent)\s*=/);

console.log("agent-steward policy: coordinator skill, spawn boundary, review and worktree controls passed");
