import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
const f = JSON.parse(readFileSync(process.argv[2], "utf8"));
const root = mkdtempSync(join(tmpdir(), "steward-wrapper-"));
const key = "SyntheticWrapper-Only-'$(touch secret-executed)";
const capture = join(root, "capture.json");
const env = {
  PATH: process.env.PATH, TEST_CAPTURE: capture, TEST_STATUS: "37",
  TYPESAFE_API_KEY: "InheritedSynthetic-NotAFallback", OPENAI_API_KEY: "ProviderSynthetic"
};
const secret = join(root, f.secretFile);
function invoke(args, traced = false) {
  rmSync(capture, { force: true });
  return spawnSync(traced ? f.bash : f.wrapper, traced ? ["-x", f.wrapper, ...args] : args,
    { cwd: root, env, encoding: "utf8", timeout: 5000 });
}
function rejected(traced = false) {
  const r = invoke(["router", "start", "synthetic task", "--dry-run"], traced);
  assert.equal(r.status, 1);
  assert.equal(r.stdout, "");
  const diagnostic = "agent-steward: credential unavailable\n";
  if (traced) {
    const marker = "+ set +x\n";
    const traceEnd = r.stderr.lastIndexOf(marker);
    assert.notEqual(traceEnd, -1);
    assert.equal(r.stderr.slice(traceEnd + marker.length), diagnostic);
  } else {
    assert.equal(r.stderr, diagnostic);
  }
  assert.equal(existsSync(capture), false);
  assert.ok(!r.stderr.includes(key));
  assert.ok(!r.stderr.includes(env.TYPESAFE_API_KEY));
}
function credentialFree() {
  for (const args of [
    ["router", "list"],
    ["router", "list", "--json"],
    ["router", "show", "synthetic-request-id"],
    ["--help"],
    ["-h"],
    ["router", "--help"],
  ]) {
    const r = invoke(args, true);
    assert.equal(r.status, 37, r.stderr);
    assert.equal(r.stdout, "");
    assert.deepEqual(JSON.parse(readFileSync(capture, "utf8")), {
      argv: args, cwd: root, provider: env.OPENAI_API_KEY,
    });
    assert.ok(!r.stderr.includes(env.TYPESAFE_API_KEY));
  }
}
try {
  assert.deepEqual(readdirSync(dirname(f.wrapper)), ["agent-steward"]);
  credentialFree(); // missing secret must not block history/help or leak an inherited key
  rejected(); // missing; inherited key must not rescue it
  mkdirSync(secret);
  rejected(); // nonregular file is not credential data
  rmSync(secret, { recursive: true });
  for (const text of ["", "\n", " \t\r\n"]) {
    writeFileSync(secret, text, { mode: 0o600 });
    rejected();
  }
  for (const bytes of [Buffer.from([0]), Buffer.from("a\0b"), Buffer.from(" \t\0\r\n")]) {
    writeFileSync(secret, bytes, { mode: 0o600 });
    rejected();
    rejected(true);
  }
  writeFileSync(secret, key);
  chmodSync(secret, 0);
  // An unreadable-file test run as root is not evidence of this boundary.
  assert.equal(spawnSync(f.bash, ["-c", '[ -r "$1" ]', "test", secret],
    { cwd: root, env }).status, 1, "run this check unprivileged (Nix sandbox)");
  rejected();
  credentialFree(); // unreadable secret must not block history/help
  chmodSync(secret, 0o600);
  credentialFree(); // a readable key must not be loaded for history/help either
  const task = "literal '\" ; $(touch task-executed)\nsecond line";
  for (const args of [
    ["router", "start", task, "--dry-run", "--json"],
    ["router", "start", "--dry-run", "--json", "--", "--config not-an-override\n--help"],
    ["stop", "check"]
  ]) {
    writeFileSync(secret, key + "\n", { mode: 0o600 });
    const r = invoke(args, true);
    assert.equal(r.status, 37, r.stderr);
    assert.equal(r.stdout, "");
    assert.ok(!r.stderr.includes(key));
    assert.ok(!r.stderr.includes(env.TYPESAFE_API_KEY));
    assert.deepEqual(JSON.parse(readFileSync(capture, "utf8")), {
      argv: ["--config", f.configFile, ...args], cwd: root, key,
      provider: env.OPENAI_API_KEY
    });
  }
  for (const marker of ["secret-executed", "task-executed", "secret-path-executed", "config-path-executed"])
    assert.equal(existsSync(join(root, marker)), false);
} finally {
  if (existsSync(secret)) chmodSync(secret, 0o600);
  rmSync(root, { recursive: true, force: true });
}
// No real SOPS key is used: create an exclusive synthetic file, never overwrite
// an existing path. Darwin uses the same OS lookup as SOPS; Linux uses private XDG data.
const scratch = mkdtempSync(join(tmpdir(), "steward-placeholder-"));
const xdg = join(scratch, "runtime '&$()\n");
mkdirSync(xdg, { mode: 0o700 });
let runtimeDir = xdg;
if (process.platform === "darwin") {
  const lookup = spawnSync("/usr/bin/getconf", ["DARWIN_USER_TEMP_DIR"], { encoding: "utf8" });
  assert.equal(lookup.status, 0);
  runtimeDir = lookup.stdout.replace(/\n+$/, "");
}
assert.ok(runtimeDir.startsWith("/"));
const templatedSecret = f.templatedSecretFile.replaceAll("%r", runtimeDir);
const templatedCapture = join(scratch, "capture.json");
let created = false;
try {
  writeFileSync(templatedSecret, key + "\n", { mode: 0o600, flag: "wx" });
  created = true;
  const templateEnv = { ...env, XDG_RUNTIME_DIR: xdg, TEST_CAPTURE: templatedCapture };
  const r = spawnSync(f.templatedWrapper, ["router", "start", "synthetic task", "--dry-run"], {
    cwd: scratch, env: templateEnv, encoding: "utf8", timeout: 5000,
  });
  assert.equal(r.status, 37, r.stderr);
  assert.equal(JSON.parse(readFileSync(templatedCapture, "utf8")).key, key);
  assert.ok(!r.stderr.includes(key));
  if (process.platform !== "darwin") {
    for (const value of ["", "relative-runtime"]) {
      rmSync(templatedCapture, { force: true });
      const bad = spawnSync(f.templatedWrapper, ["router", "start", "synthetic task", "--dry-run"], {
        cwd: scratch, env: { ...templateEnv, XDG_RUNTIME_DIR: value }, encoding: "utf8", timeout: 5000,
      });
      assert.equal(bad.status, 1);
      assert.equal(bad.stdout, "");
      assert.equal(bad.stderr, "agent-steward: credential unavailable\n");
      assert.equal(existsSync(templatedCapture), false);
    }
  }
} finally {
  if (created) rmSync(templatedSecret, { force: true });
  rmSync(scratch, { recursive: true, force: true });
}
