import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
const f = JSON.parse(readFileSync(process.argv[2], "utf8"));
assert.ok(statSync(`${f.argvPlugin}/dispatch.sh`).isFile());
assert.equal(statSync(`${f.argvPlugin}/herdr-plugin.toml`).mode & 0o111, 0);
assert.ok(statSync(`${f.stopPlugin}/run.sh`).isFile());
assert.equal(statSync(`${f.stopPlugin}/herdr-plugin.toml`).mode & 0o111, 0);
assert.match(readFileSync(`${f.stopPlugin}/herdr-plugin.toml`, "utf8"), /min_herdr_version/);
assert.match(readFileSync(`${f.stopPlugin}/run.sh`, "utf8"), /agent-steward-herdr-adapter/);
assert.doesNotMatch(readFileSync(`${f.stopPlugin}/run.sh`, "utf8"), /sessionVariables/);
assert.equal(readFileSync(`${f.stopPlugin}/herdr-plugin.toml`, "utf8"),
  readFileSync(`${f.upstreamRecover}/herdr-plugin.toml`, "utf8"));
const root = mkdtempSync(join(tmpdir(), "steward-plugin-wrapper-"));
const syntheticKey = "synthetic-wrapper-key";
try {
  writeFileSync(join(root, "synthetic secret.key"), syntheticKey, { mode: 0o600 });
  for (const command of ["event", "scheduler"]) {
    const result = spawnSync(`${f.stopPlugin}/run.sh`, [command], {
      cwd: root, env: {}, encoding: "utf8", timeout: 5000,
    });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stdout, `${syntheticKey}\n${command}\n`);
  }
  const rejected = spawnSync(`${f.stopPlugin}/run.sh`, ["invalid"], {
    cwd: root, env: {}, encoding: "utf8", timeout: 5000,
  });
  assert.equal(rejected.status, 2);
  assert.equal(rejected.stdout, "");
  assert.doesNotMatch(readFileSync(`${f.stopPlugin}/run.sh`, "utf8"), new RegExp(syntheticKey));
} finally {
  rmSync(root, { recursive: true, force: true });
}
const read = p => readFileSync(p, "utf8");
// Only the dedicated option controls approval; CLI settings pass through unchanged.
assert.deepEqual(JSON.parse(read(f.approvalEnabledJson)), { auto_approve: true });
assert.deepEqual(JSON.parse(read(f.approvalDisabledJson)), { auto_approve: false });
assert.deepEqual(JSON.parse(read(f.approvalMissingJson)), { auto_approve: false });
const original = JSON.parse(read(f.defaultJson));
assert.equal(Object.hasOwn(original, "auto_approve"), false);
assert.deepEqual(JSON.parse(read(f.approvalEnabledCliJson)), original);
assert.deepEqual(JSON.parse(read(f.passthroughJson)), { ...original, auto_approve: true });
assert.deepEqual(JSON.parse(read(f.passthroughApprovalJson)), { auto_approve: false });
const changed = JSON.parse(read(f.overrideJson));
function sorted(value) {
  if (Array.isArray(value)) return value.map(sorted);
  if (value && typeof value === "object") return Object.fromEntries(
    Object.keys(value).sort().map(k => [k, sorted(value[k])]));
  return value;
}
assert.equal(createHash("sha256").update(JSON.stringify(sorted(original))).digest("hex"),
  "d2f4f074ead32c15d015a6580153615d7830e9d9c7055b4a8690a1911dc6dd40");
assert.equal(original.candidates.find(c => c.tool === "agy").quota_pool, "gemini");
assert.deepEqual(original.tools, ["pi", "agy"]);
assert.equal(Object.hasOwn(original, "accounts"), false);
assert.deepEqual(original.candidates.map(c => c.id), [
  "sol-pi", "astra-pi", "luna-pi", "grok-4.6-pi", "gemini-flash-agy"
]);
const expected = structuredClone(original);
expected.thresholds.risky = 0.7;
expected.candidates.find(c => c.id === "gemini-flash-agy").capabilities += "; declarative override";
assert.deepEqual(changed, expected);
const expectedPartial = structuredClone(original);
expectedPartial.thresholds.risky = 0.8;
assert.deepEqual(JSON.parse(read(f.partialJson)), expectedPartial);
const expectedLists = structuredClone(original);
expectedLists.tools = ["agy"];
expectedLists.candidates = original.candidates.filter(c => c.tool === "agy");
assert.deepEqual(JSON.parse(read(f.listsJson)), expectedLists);
assert.doesNotMatch(read(f.defaultWrapper), /--config/);
assert.doesNotMatch(read(f.overrideWrapper), /--config/);
assert.notEqual(f.defaultJson, f.overrideJson);
assert.doesNotMatch(f.piModule, /skills\.agent-steward\s*=/);
assert.match(f.stewardModule, /skills\.agent-steward\s*=/);
assert.match(f.defaultModule, /\.\/agent-steward(?:\s|$)/);
assert.deepEqual(
  [f.newModule, f.newConfig, f.newWrapper, f.oldModule, f.oldConfig, f.oldWrapper],
  [true, true, true, false, false, false]
);
assert.match(f.stewardModule, /import \.\/wrapper\.nix/);
assert.match(f.stewardModule, /import \.\/config\.nix/);
assert.match(f.sopsModule, /defaultSopsFile\s*=/); // existing production default retained, no secret contents read
assert.match(f.stewardModule, /systemd\.user\.timers\.agent-steward-quota-refresh/);
assert.match(f.stewardModule, /quota refresh/);
assert.match(f.stewardModule, /OnCalendar = "hourly"/);
assert.doesNotMatch(f.stewardModule, /temp\/config|readFile.*secret|launchd|sessionVariables/);
assert.match(f.stewardModule, /TYPESAFE_API_KEY_FILE/);
assert.match(f.stewardModule, /AGENT_STEWARD_HERDR_ADAPTER/);
assert.doesNotMatch(f.stewardModule, /TYPESAFE_API_KEY\s*=\s/);
assert.ok(["x86_64-linux", "aarch64-linux", "aarch64-darwin"].includes(f.system));
