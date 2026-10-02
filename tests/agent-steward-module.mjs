import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { readFileSync, statSync } from "node:fs";
const f = JSON.parse(readFileSync(process.argv[2], "utf8"));
assert.equal(statSync(`${f.argvPlugin}/dispatch.sh`).mode & 0o111, 0o111);
assert.equal(statSync(`${f.argvPlugin}/herdr-plugin.toml`).mode & 0o111, 0);
const read = p => readFileSync(p, "utf8");
const original = JSON.parse(read(f.defaultJson));
const changed = JSON.parse(read(f.overrideJson));
function sorted(value) {
  if (Array.isArray(value)) return value.map(sorted);
  if (value && typeof value === "object") return Object.fromEntries(
    Object.keys(value).sort().map(k => [k, sorted(value[k])]));
  return value;
}
assert.equal(createHash("sha256").update(JSON.stringify(sorted(original))).digest("hex"),
  "9d2385b91dbc66162668fbe60bf90143f7e85ce27ee1aebbc59093e0173e6630");
assert.deepEqual(original.tools, ["pi", "agy"]);
assert.equal(Object.hasOwn(original, "accounts"), false);
assert.deepEqual(original.candidates.map(c => c.id), [
  "sol-pi", "astra-pi", "luna-pi", "grok-4.6-pi", "gemini-flash-low-agy", "gemini-flash-medium-agy", "gemini-flash-high-agy"
]);
const expected = structuredClone(original);
expected.thresholds.risky = 0.7;
expected.candidates.find(c => c.id === "gemini-flash-high-agy").capabilities += "; declarative override";
assert.deepEqual(changed, expected);
const expectedPartial = structuredClone(original);
expectedPartial.thresholds.risky = 0.8;
assert.deepEqual(JSON.parse(read(f.partialJson)), expectedPartial);
const expectedLists = structuredClone(original);
expectedLists.tools = ["agy"];
expectedLists.candidates = original.candidates.filter(c => c.tool === "agy");
assert.deepEqual(JSON.parse(read(f.listsJson)), expectedLists);
assert.ok(read(f.defaultWrapper).includes(f.defaultJson));
assert.ok(read(f.overrideWrapper).includes(f.overrideJson));
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
assert.doesNotMatch(f.stewardModule, /temp\/config|readFile.*secret|sessionVariables|launchd/);
assert.ok(["x86_64-linux", "aarch64-linux", "aarch64-darwin"].includes(f.system));
