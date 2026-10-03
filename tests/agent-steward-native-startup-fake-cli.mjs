import assert from 'node:assert/strict';
import { appendFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const pkg = process.env.STEWARD_TEST_PACKAGE;
const imp = (name) => import(pathToFileURL(join(pkg, 'lib/agent-steward/dist/src', name + '.js')));
const { run } = await imp('cli');
const { createRuntime } = await imp('main');
const { launchForeground } = await imp('process');

process.exitCode = await run(process.argv.slice(2), {
  ...createRuntime(),
  env: { ...process.env, HOME: process.env.HOME || '/tmp' },
  cwd: process.cwd(),
  stdout: (text) => process.stdout.write(text),
  stderr: (text) => process.stderr.write(text),
  now: () => new Date('2026-09-30T12:00:00Z'),
  newRequestId: () => 'offline-native-start',
  terminal: { stdin: true, stdout: true },
  post: async (request) => {
    assert.equal(request.url, 'https://api.typesafe.ai/v1/systemone');
    assert.equal(request.headers.authorization, 'Bearer SyntheticNativeStartup-KeyOnly');
    assert.equal(request.headers.authorization, `Bearer ${process.env.TYPESAFE_API_KEY}`);
    const wire = JSON.parse(request.body);
    assert.deepEqual(Object.keys(wire.questions), ['pair']);
    assert.equal(wire.state.task, process.env.EXPECTED_TASK);
    const keys = Object.keys(wire.questions.pair.criteria);
    const winner = process.env.TEST_PAIR;
    assert.ok(keys.includes(winner));
    assert.ok(!request.body.includes(process.env.TYPESAFE_API_KEY));
    appendFileSync(process.env.HTTP_CAPTURE, JSON.stringify(wire) + '\n', { mode: 0o600 });
    return {
      status: 200,
      body: JSON.stringify({
        model: wire.model,
        usage: {},
        answers: {
          pair: {
            type: 'choice',
            choice: winner,
            confidence: 1,
            probabilities: Object.fromEntries(keys.map((key) => [key, key === winner ? 1 : 0])),
          },
        },
      }),
    };
  },
  launch: (command) => launchForeground(command, { cwd: process.cwd(), env: process.env }),
});
