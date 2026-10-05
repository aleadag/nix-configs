import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, realpathSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";
const f = JSON.parse(readFileSync(process.argv[2], "utf8"));
const imp = name => import(pathToFileURL(join(f.raw, "lib/agent-steward/dist/src", name + ".js")));
const { ConfigSchema, ResultSchema } = await imp("contracts");
const { loadConfig } = await imp("config");
const { validateCandidateSyntax } = await imp("commands");
const original = JSON.parse(readFileSync(f.generated, "utf8"));
const changed = JSON.parse(readFileSync(f.overridden, "utf8"));
const expectedChanged = {
  ...original,
  thresholds: { ...original.thresholds, risky: 0.7 },
  jev: { ...original.jev, model: "jev-declarative-override" }
};
assert.deepEqual(changed, expectedChanged);
const candidateIds = ["sol-pi", "astra-pi", "luna-pi", "grok-4.6-pi", "gemini-flash-agy"];
for (const [path, value, model] of [[f.generated, original, "jev-1.13.0"], [f.overridden, changed, "jev-declarative-override"]]) {
  const expected = {
    tools: value.tools,
    candidates: value.candidates,
    thresholds: value.thresholds,
    evaluator: { type: "jev", provider: "typesafe", model }
  };
  assert.equal(Object.hasOwn(value, "accounts"), false);
  assert.deepEqual(value.candidates.map(c => c.quota_bucket), ["pi_codex", "pi_codex", "pi_codex", "pi_xai", "antigravity"]);
  assert.deepEqual(value.candidates.map(c => c.cost), [20, 100, 1, 13, 8]);
  assert.deepEqual(value.candidates.map(c => c.id), candidateIds);
  assert.deepEqual(ConfigSchema.parse(value), expected);
  const loaded = await loadConfig(path, {
    env: {}, cwd: "/", readText: async p => readFileSync(p, "utf8")
  });
  assert.deepEqual(loaded, expected);
  loaded.candidates.forEach(validateCandidateSyntax);
  const agy = loaded.candidates.filter(c => c.tool === "agy");
  assert.equal(agy.length, 1);
  assert.equal(agy[0].model, "gemini-3.8-flash");
  assert.deepEqual(agy[0].thinking_levels.map(level => level.id), ["low", "medium", "high"]);
}
assert.equal(changed.thresholds.risky, 0.7);
assert.equal(changed.jev.model, "jev-declarative-override");
assert.equal(realpathSync(join(f.raw, "lib/agent-steward/bun")), realpathSync(f.bunPackage));
assert.equal(spawnSync(f.bun, ["--version"], { encoding: "utf8", env: { PATH: "" } }).stdout.trim(),
  f.expectedBunVersion);
assert.equal(readFileSync(join(f.raw, "share/agent-steward/skills/agent-steward/SKILL.md"), "utf8"),
  readFileSync(f.skillSource, "utf8"));
assert.deepEqual(readdirSync(dirname(f.wrapper)), ["agent-steward"]);
const root = mkdtempSync(join(tmpdir(), "steward-real-cli-"));
const key = "SyntheticIntegrated-NotARealCredential";
const secret = join(root, f.secretFile);
const httpCapture = join(root, "http.jsonl");
const nativeCapture = join(root, "native.jsonl");
const bin = join(root, "bin");
const xdg = join(root, "xdg");
const configDir = join(xdg, "agent-steward");
const configFile = join(configDir, "config.json");
function lines(path) {
  return existsSync(path) ? readFileSync(path, "utf8").trim().split("\n").filter(Boolean).map(JSON.parse) : [];
}
function clear() {
  rmSync(httpCapture, { force: true });
  rmSync(nativeCapture, { force: true });
}
function call(exe, args, pair = "sol-pi", input) {
  return spawnSync(exe, args, {
    cwd: root, env: {
      PATH: bin, HOME: root, XDG_CONFIG_HOME: xdg,
      STEWARD_TEST_PACKAGE: f.raw, TEST_PAIR: pair,
      TEST_HTTP_CAPTURE: httpCapture, STUB_CAPTURE: nativeCapture,
      TYPESAFE_API_KEY: "InheritedIntegrated-NotUsed",
      typesafe_api_key: "SyntheticLowerCase-ToBeStripped", OPENAI_API_KEY: "SyntheticProvider-Only"
    }, input, encoding: "utf8", timeout: 15000
  });
}
function noLeak(r) {
  assert.ok(!r.stdout.includes(key));
  assert.ok(!r.stderr.includes(key));
  for (const p of [httpCapture, nativeCapture]) if (existsSync(p)) assert.ok(!readFileSync(p, "utf8").includes(key));
}
try {
  mkdirSync(bin);
  mkdirSync(configDir, { recursive: true });
  writeFileSync(configFile, readFileSync(f.generated));
  writeFileSync(secret, key + "\n", { mode: 0o600 });
  for (const tool of ["pi", "agy"]) {
    writeFileSync(join(bin, tool), `#!${f.bun}\n` +
      `const fs = require("node:fs"); fs.appendFileSync(process.env.STUB_CAPTURE, JSON.stringify({` +
      `tool: ${JSON.stringify(tool)}, argv: process.argv.slice(2), cwd: process.cwd(),` +
      `keyNames: Object.keys(process.env).filter(k => k.toUpperCase() === "TYPESAFE_API_KEY"),` +
      `provider: process.env.OPENAI_API_KEY }) + "\\n", { mode: 0o600 }); process.exit(23);\n`,
      { mode: 0o700 });
  }
  const help = call(f.wrapper, ["--help"]);
  assert.equal(help.status, 0, help.stderr);
  assert.match(help.stdout, /router start/);
  assert.match(help.stdout, /stop check/);
  noLeak(help);
  const localStop = {
    schema_version: 2, request_id: "local-stop", agent: { id: "synthetic", tool: "pi", pane_id: "no-real-pane", session_id: null },
    status: "blocked", current_episode_id: "synthetic-episode", context: null, automatic_approval_forbidden: true,
    retry: { failure_episode_id: "synthetic-episode", first_observed_at: "2026-09-30T10:00:00Z",
      attempt_count: 0, last_attempt_at: null, quota_check_count: 0, last_quota_check_at: null }
  };
  const stop = call(f.wrapper, ["stop", "check"], "sol-pi", JSON.stringify(localStop));
  assert.equal(stop.status, 2, stop.stderr);
  assert.equal(JSON.parse(stop.stdout).reason_code, "insufficient_context");
  assert.equal(existsSync(httpCapture), false);
  noLeak(stop);
  // Duplicate caller config flags are rejected before either file is read.
  const duplicate = call(f.wrapper, ["--config", join(root, "not-read.json"), "router", "start", "task", "--config", join(root, "also-not-read.json"), "--dry-run", "--json"]);
  assert.equal(duplicate.status, 1);
  assert.equal(JSON.parse(duplicate.stdout).reason_code, "invalid_input");
  assert.equal(existsSync(httpCapture), false);
  assert.equal(existsSync(nativeCapture), false);
  noLeak(duplicate);
  // Actual compiled CLI with fake HTTP: the complete multi-tool config reached the evaluator.
  const task = "planner: literal '\" $(touch task-executed)\nsecond line";
  for (const pair of ["sol-pi", "gemini-flash-agy"]) {
    clear();
    const preview = call(f.integrated, ["router", "start", "--dry-run", "--json", "--", "--config literal task"], pair);
    assert.equal(preview.status, 0, preview.stderr);
    const p = ResultSchema.parse(JSON.parse(preview.stdout));
    assert.equal(p.decision, "selected");
    assert.equal(p.selected.candidate_id, pair);
    if (pair === "gemini-flash-agy") {
      assert.equal(p.selected.model, "gemini-3.8-flash");
      assert.equal(p.selected.thinking_level, "high");
      assert.deepEqual(p.planned_command.args, ["--model=gemini-3.8-flash", "--effort=high"]);
      assert.equal(lines(httpCapture)[1].wire.state.candidate.model, "gemini-3.8-flash");
    }
    assert.equal(lines(httpCapture)[0].wire.state.task, "--config literal task");
    assert.deepEqual(lines(httpCapture)[0].wire.state.candidates.map(c => c.id), original.candidates.map(c => c.id));
    assert.equal(lines(httpCapture)[0].wire.model, "jev-1.13.0");
    assert.equal(lines(nativeCapture).length, 0);
    noLeak(preview);
    clear();
    const live = call(f.integrated, ["router", "start", task], pair);
    assert.equal(live.status, 23, live.stderr);
    const records = lines(nativeCapture);
    assert.equal(records.length, 1);
    const pi = pair === "sol-pi";
    assert.deepEqual(records[0], {
      tool: pi ? "pi" : "agy", cwd: root, keyNames: [], provider: "SyntheticProvider-Only",
      argv: pi ? ["--provider", "openai-codex", "--model", "gpt-6.1-sol", "--thinking", "high", "--", "User task:\n" + task]
        : ["--model=gemini-3.8-flash", "--effort=high", "--prompt-interactive=User task:\n" + task]
    });
    const liveRequests = lines(httpCapture);
    assert.equal(liveRequests.length, 2);
    for (const { wire } of liveRequests) assert.equal(wire.state.task, task);
    noLeak(live);
  }
  clear();
  writeFileSync(configFile, readFileSync(f.overridden));
  const overridePreview = call(f.integratedOverride, ["router", "start", "override task", "--dry-run", "--json"], "gemini-flash-agy");
  assert.equal(overridePreview.status, 0, overridePreview.stderr);
  const overriddenPreview = ResultSchema.parse(JSON.parse(overridePreview.stdout));
  assert.equal(overriddenPreview.evaluations.pair.model, "jev-declarative-override");
  assert.equal(lines(httpCapture)[0].wire.model, "jev-declarative-override");
  assert.equal(lines(nativeCapture).length, 0);
  noLeak(overridePreview);
  clear();
  writeFileSync(configFile, readFileSync(f.generated));
  const duplicateConfig = call(f.integrated, ["router", "start", "task", "--config", "ignored.json", "--config", "also-ignored.json", "--dry-run", "--json"]);
  assert.equal(duplicateConfig.status, 1);
  assert.equal(JSON.parse(duplicateConfig.stdout).reason_code, "invalid_input");
  assert.equal(lines(httpCapture).length, 0);
  assert.equal(lines(nativeCapture).length, 0);
  noLeak(duplicateConfig);
  assert.equal(existsSync(join(root, "task-executed")), false);
} finally {
  rmSync(root, { recursive: true, force: true });
}
