import assert from "node:assert/strict";
import { appendFileSync } from "node:fs";
import { pathToFileURL } from "node:url";
import { join } from "node:path";
const pkg = process.env.STEWARD_TEST_PACKAGE;
const imp = name => import(pathToFileURL(join(pkg, "lib/agent-steward/dist/src", name + ".js")));
const { run } = await imp("cli");
const { launchForeground } = await imp("process");
const { readFileText, readBoundedUtf8 } = await imp("io");
const post = async request => {
  const wire = JSON.parse(request.body);
  assert.equal(request.url, "https://api.typesafe.ai/v1/systemone");
  assert.ok(request.headers.authorization === `Bearer ${process.env.TYPESAFE_API_KEY}`);
  assert.ok(!request.body.includes(process.env.TYPESAFE_API_KEY));
  const id = Object.keys(wire.questions)[0];
  assert.equal(Object.keys(wire.questions).length, 1);
  const keys = Object.keys(wire.questions[id].criteria);
  const winner = id === "pair" ? process.env.TEST_PAIR : "high";
  assert.ok(keys.includes(winner));
  appendFileSync(process.env.TEST_HTTP_CAPTURE,
    JSON.stringify({ headerMatched: true, wire }) + "\n", { mode: 0o600 });
  return { status: 200, body: JSON.stringify({
    model: wire.model, usage: {}, answers: { [id]: {
      type: "choice", choice: winner, confidence: 1,
      probabilities: Object.fromEntries(keys.map(k => [k, k === winner ? 1 : 0]))
    } }
  }) };
};
process.exitCode = await run(process.argv.slice(2), {
  env: { ...process.env, HOME: process.env.HOME || '/tmp' }, cwd: process.cwd(), readText: readFileText,
  appendText: async () => {}, readTextIfPresent: async () => null,
  mkdirp: async () => {}, chmod: async () => {},
  readStdin: () => readBoundedUtf8(process.stdin),
  stdout: text => process.stdout.write(text), stderr: text => process.stderr.write(text),
  now: () => new Date("2026-09-30T12:00:00Z"), newRequestId: () => "offline-wrapper-request",
  post, terminal: { stdin: true, stdout: true },
  launch: command => launchForeground(command, { cwd: process.cwd(), env: process.env })
});
