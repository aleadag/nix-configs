import assert from "node:assert/strict";
import { readFileSync } from "node:fs";

const config = JSON.parse(readFileSync(process.argv[2], "utf8"));
const settings = JSON.parse(config.piSettings);
assert.ok(
  !(settings.packages ?? []).some((pkg) => pkg.source === config.retiredPackage),
  "the retired Pi Herdr package must not be installed",
);
assert.doesNotMatch(config.piSettings, /pi-herdr-subagents/);
for (const plugin of config.herdrPlugins) {
  assert.doesNotMatch(plugin, /pi-herdr-subagents/);
  assert.doesNotMatch(
    readFileSync(`${plugin}/herdr-plugin.toml`, "utf8"),
    /^id\s*=\s*"pi-herdr-subagents"/m,
    "the retired Herdr plugin must not be registered",
  );
}

for (const role of ["planner", "worker", "reviewer"]) {
  const frontmatter = config[role].split("---")[1];
  assert.match(frontmatter, new RegExp(`^name: ${role}$`, "m"));
  assert.match(frontmatter, /^auto-exit: true$/m);
  assert.doesNotMatch(frontmatter, /^(model|thinking):/m, "role definitions must not pin routing settings");
  assert.doesNotMatch(frontmatter, /^tools:.*\b(?:subagent(?:_resume|_interrupt)?|subagents_list)\b/m);
}

assert.ok(config.stewardSkill, "the coordinator must discover the agent-steward skill");
assert.match(config.coordinatorSkill, /name: agent-to-agent/);
assert.match(config.coordinatorSkill, /steward-spawn/);
assert.match(config.subagentsSkill, /name: subagents/);
assert.match(config.subagentsSkill, /agents\/planner\.md/);
assert.match(config.subagentsSkill, /agents\/worker\.md/);
assert.match(config.subagentsSkill, /agents\/reviewer\.md/);
assert.match(config.subagentsSkill, /Follow the `agent-to-agent` skill/);
assert.match(config.subagentsSkill, /Never call `subagent`/);
assert.doesNotMatch(config.subagentsSkill, /--config|--dry-run|SOPS|TYPESAFE_API_KEY|planned_command/);
assert.doesNotMatch(config.context, /Pi Herdr delegation|## Pi subagents/);
assert.ok(!config.context.includes("Model and thinking defaults live in the role files"));
console.log("Pi Herdr retirement: package/plugin absent, unpinned roles and coordinator guidance passed");
