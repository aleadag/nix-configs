import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";

const config = JSON.parse(readFileSync(process.argv[2], "utf8"));
const { parseAgentDefinition } = await import(pathToFileURL(join(config.upstream, "src/agents.ts")));
const { buildLaunchPlan } = await import(pathToFileURL(join(config.upstream, "src/launch.ts")));
const root = mkdtempSync(join(tmpdir(), "pi-herdr-config-"));

try {
  const agentDir = join(root, "agent");
  mkdirSync(agentDir);
  process.env.PI_CODING_AGENT_DIR = agentDir;
  const piBin = join(root, "pi");
  writeFileSync(piBin, `#!${process.execPath}\nimport { writeFileSync } from "node:fs";\nwriteFileSync(process.env.CAPTURE, JSON.stringify({ args: process.argv.slice(2), cwd: process.cwd(), denied: process.env.PI_DENY_TOOLS }));\n`);
  chmodSync(piBin, 0o755);

  for (const [role, model, thinking] of [
    ["planner", "openai-codex/gpt-6.1-sol", "xhigh"],
    ["worker", "openai-codex/gpt-6-luna", "xhigh"],
    ["reviewer", "openai-codex/gpt-6-sol", "medium"],
  ]) {
    const definition = parseAgentDefinition(config[role], role);
    assert.equal(definition.name, role);
    assert.equal(definition.autoExit, true);
    const cwd = join(root, role);
    mkdirSync(cwd);
    const capture = join(root, `${role}.json`);
    const plan = buildLaunchPlan(
      { name: `${role}-task`, agent: role, task: "Read the supplied brief and report verification.", cwd },
      definition,
      {
        sessionDir: join(root, "sessions"),
        sessionId: "coordinator",
        parentSessionFile: join(root, "parent.jsonl"),
        parentCwd: root,
        id: role,
        env: {
          PATH: process.env.PATH,
          PI_CODING_AGENT_DIR: agentDir,
          PI_HERDR_PI_BIN: piBin,
          PI_HERDR_LAUNCH_PREFIX: "",
          PI_HERDR_HOLD_OPEN_SECS: "0",
        },
      },
    );
    assert.equal(plan.seedSession, null, "roles must not inherit coordinator history");
    for (const file of plan.files) {
      mkdirSync(dirname(file.path), { recursive: true });
      writeFileSync(file.path, file.content);
    }
    const result = spawnSync("bash", [plan.launchScriptFile], {
      env: { ...process.env, CAPTURE: capture },
      encoding: "utf8",
    });
    assert.equal(result.status, 0, result.stderr);
    const launched = JSON.parse(readFileSync(capture, "utf8"));
    assert.equal(launched.args[launched.args.indexOf("--model") + 1], `${model}:${thinking}`);
    assert.equal(launched.cwd, cwd, "the agent must run in its assigned worktree");
    assert.ok(launched.args.includes("--append-system-prompt"));
    assert.ok(!launched.args.includes("--system-prompt"));
    assert.ok(launched.denied.split(",").includes("subagent"));
    assert.ok(launched.denied.split(",").includes("subagent_resume"));
  }

  for (const file of ["herdr-plugin.toml", "dispatch.sh"]) {
    assert.equal(
      readFileSync(join(config.plugin, file), "utf8"),
      readFileSync(join(config.upstream, "herdr-plugin", file), "utf8"),
      "Pi and Herdr must use the same pinned upstream source",
    );
  }
  console.log("Pi Herdr configuration: role launches, worktree cwd, context isolation and plugin parity passed");
} finally {
  rmSync(root, { recursive: true, force: true });
}
