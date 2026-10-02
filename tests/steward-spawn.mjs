import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, statSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
// Wrong argv, leaked credentials, skipped validation or shell interpolation must fail.
const [spawn, bash, dispatch] = process.argv.slice(2);
assert.ok(existsSync(spawn), "steward-spawn implementation is missing");
const root = mkdtempSync(join(tmpdir(), "steward-spawn-"));
const cwd = join(root, "cwd 'quoted'\n$(touch injected)");
mkdirSync(cwd);
const capture = join(root, "herdr.argv");
const renameCapture = join(root, "herdr.rename");
const childCapture = join(root, "child.argv");
const envFile = join(root, "env");
const env = { PATH: `${root}:${process.env.PATH}`, TYPESAFE_API_KEY: "SyntheticInherited", TEST_CAPTURE: capture, TEST_RENAME: renameCapture, TEST_CHILD: childCapture, TEST_ENV: envFile };
const scripts = [];
function executable(name, text) {
  const path = join(root, name);
  writeFileSync(path, `#!${bash}\n${text}`);
  chmodSync(path, 0o755);
}
executable(
  "herdr",
  [
    'if [ "$1" = pane ] && [ "$2" = rename ]; then printf "%s\\0" "$@" > "$TEST_RENAME"; exit 0; fi',
    "if [ \"$1\" = pane ] && [ \"$2\" = layout ]; then printf '%s\\n' '{\"result\":{\"layout\":{\"area\":{\"width\":160,\"height\":80},\"panes\":[{\"pane_id\":\"w1:p2\",\"rect\":{\"width\":40,\"height\":80}},{\"pane_id\":\"w1:p9\",\"rect\":{\"width\":120,\"height\":80}}]}}}'; exit 0; fi",
    'printf "%s\\0" "$@" >> "$TEST_CAPTURE"',
    'env > "$TEST_ENV"',
    "printf '%s\\n' '{\"result\":{\"plugin_pane\":{\"pane\":{\"pane_id\":\"w9:p3\"}}}}'",
    'exit "${TEST_OPEN_STATUS:-0}"',
  ].join("\n"),
);
executable("agent-steward", 'printf "%s\\0" "$@" > "$TEST_CHILD"\nprintf "%s\\0" "$PWD" >> "$TEST_CHILD"\ntrap -p TSTP >> "$TEST_CHILD"\n');
const base = ["--target-pane", "w1:p2", "--direction", "right", "--name", "unique", "--cwd", cwd];
function invoke(args, extra = {}) {
  rmSync(capture, { force: true });
  rmSync(renameCapture, { force: true });
  return spawnSync(bash, [spawn, ...args], { env: { ...env, ...extra }, encoding: "utf8", timeout: 5000 });
}
try {
  const help = invoke(["--help"]);
  assert.equal(help.status, 0, help.stderr);
  assert.match(help.stdout, /--target-pane/);
  assert.match(help.stdout, /\[--direction <right\|down>\]/);
  assert.equal(existsSync(capture), false);
  const instruction = "literal ' \" $(touch injected)\n--help --";
  const result = invoke([...base, "--", instruction]);
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.stdout, "unique\n");
  const argv = readFileSync(capture, "utf8").split("\0").filter(Boolean);
  const launch = argv[argv.indexOf("--env") + 1].replace(/^PI_HERDR_LAUNCH_SCRIPT=/, "");
  scripts.push(launch);
  assert.deepEqual(argv, ["plugin", "pane", "open", "--plugin", "steward-argv", "--entrypoint", "argv", "--placement", "split", "--target-pane", "w1:p2", "--direction", "right", "--cwd", cwd, "--env", `PI_HERDR_LAUNCH_SCRIPT=${launch}`, "--no-focus"]);
  assert.deepEqual(readFileSync(renameCapture, "utf8").split("\0").filter(Boolean), ["pane", "rename", "w9:p3", "unique"]);
  const auto = invoke(["--target-pane", "w1:p2", "--name", "unique", "--cwd", cwd, "--", instruction]);
  assert.equal(auto.status, 0, auto.stderr);
  const autoArgv = readFileSync(capture, "utf8").split("\0").filter(Boolean);
  assert.equal(autoArgv[autoArgv.indexOf("--target-pane") + 1], "w1:p9");
  assert.equal(autoArgv[autoArgv.indexOf("--direction") + 1], "right");
  scripts.push(autoArgv[autoArgv.indexOf("--env") + 1].replace(/^PI_HERDR_LAUNCH_SCRIPT=/, ""));
  assert.equal(statSync(launch).mode & 0o777, 0o600);
  assert.equal(statSync(join(launch, "..")).mode & 0o777, 0o700);
  assert.ok(!readFileSync(envFile, "utf8").includes("TYPESAFE_API_KEY="));
  const child = spawnSync(bash, [dispatch], { env: { ...env, PI_HERDR_LAUNCH_SCRIPT: launch }, encoding: "utf8", timeout: 5000 });
  assert.equal(child.status, 0, child.stderr);
  assert.deepEqual(readFileSync(childCapture, "utf8").split("\0"), ["router", "start", "--", instruction, cwd, "trap -- '' SIGTSTP\n"]);
  assert.equal(existsSync(join(cwd, "injected")), false);
  for (const args of [
    base.slice(2),
    base.filter((_, i) => i !== 4 && i !== 5), base.slice(0, -2),
    [...base.slice(0, -1), "relative"], [...base.slice(0, -1), `${root}/absent`],
    base.map((x) => (x === "right" ? "left" : x)), [...base, "--ratio", "0.5"],
    [...base, "extra"],
  ]) {
    assert.equal(invoke([...args, "--", instruction]).status, 1);
    assert.equal(existsSync(capture), false);
  }
  for (const tail of [[], [instruction], ["--"], ["--", ""], ["--", instruction, "extra"]]) {
    assert.equal(invoke([...base, ...tail]).status, 1);
    assert.equal(existsSync(capture), false);
  }
  const failure = invoke([...base, "--", instruction], { TEST_OPEN_STATUS: "9" });
  assert.equal(failure.status, 9);
  const failedArgv = readFileSync(capture, "utf8").split("\0");
  scripts.push(failedArgv[failedArgv.indexOf("--env") + 1].replace(/^PI_HERDR_LAUNCH_SCRIPT=/, ""));
  assert.ok(existsSync(scripts[1]));
  for (const launchEnv of [{}, { PI_HERDR_LAUNCH_SCRIPT: "" }, { PI_HERDR_LAUNCH_SCRIPT: `${root}/missing` }]) {
    const cleanEnv = { ...env, ...launchEnv };
    delete cleanEnv.HERDR_PLUGIN_ROOT;
    assert.equal(spawnSync(bash, [dispatch], { env: cleanEnv, timeout: 5000 }).status, launchEnv.PI_HERDR_LAUNCH_SCRIPT ? 66 : 64);
  }
} finally {
  for (const script of scripts) rmSync(join(script, ".."), { recursive: true, force: true });
  rmSync(root, { recursive: true, force: true });
}
