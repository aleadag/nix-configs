import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, readFileSync, renameSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const f = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const root = mkdtempSync(join(tmpdir(), 'steward-native-startup-'));
const cwd = join(root, "assigned '\nwork");
const bin = join(root, 'bin');
const xdg = join(root, 'xdg');
const configDir = join(xdg, 'agent-steward');
const http = join(root, 'http.jsonl');
const capture = join(root, 'native.jsonl');
const key = 'SyntheticNativeStartup-KeyOnly';
const marker = 'must-not-exist';
const lines = (path) =>
  existsSync(path) ? readFileSync(path, 'utf8').trim().split('\n').filter(Boolean).map(JSON.parse) : [];
const clear = () => {
  rmSync(http, { force: true });
  rmSync(capture, { force: true });
};

// Transport is exercised by steward-spawn-check; do not launch the retired Pi plugin.
assert.ok(existsSync(f.spawn));
assert.match(f.spawnSource, /router start/);
assert.match(f.spawnSource, /plugin pane open --plugin agent-steward-launcher/);
assert.doesNotMatch(f.spawnSource, /--plugin pi-herdr-subagents|send-text|send-keys/);
// Synthetic tests cover native argv/security through the pinned router start CLI.

try {
  mkdirSync(cwd);
  mkdirSync(bin);
  mkdirSync(configDir, { recursive: true });
  writeFileSync(join(cwd, 'synthetic.key'), key + '\n', { mode: 0o600 });
  for (const tool of ['codex', 'pi', 'agy']) {
    const native =
      `#!${f.bun}\n` +
      `const fs=require('node:fs');fs.appendFileSync(process.env.NATIVE_CAPTURE,JSON.stringify({` +
      `tool:${JSON.stringify(tool)},argv:process.argv.slice(2),cwd:process.cwd(),` +
      `keyNames:Object.keys(process.env).filter(k=>k.toUpperCase()==='TYPESAFE_API_KEY'),` +
      `provider:process.env.OPENAI_API_KEY})+'\\n',{mode:0o600});` +
      `console.log('{"type":"done","task_success":true}');process.exit(23);\n`;
    writeFileSync(join(bin, tool), native, { mode: 0o700 });
  }

  let serial = 0;
  for (const effort of ['default', 'high']) {
    writeFileSync(join(configDir, 'config.json'), readFileSync(f.configs[effort]));
    for (const tool of ['codex', 'pi', 'agy']) {
      serial += 1;
      clear();
      const identity = `synthetic-startup-${serial}-${effort}-${tool}`;
      const report = join(cwd, `${identity}-report.md`);
      const task = [
        `Agent name: ${identity}`,
        `Assigned cwd: ${cwd}`,
        `Agreed synthetic report: ${report}`,
        'Complete role: Carry out the full assigned task while preserving all instruction fields.',
        'Additional guidance: Use only this disposable workspace; make no real lifecycle or TTY claims.',
        `Task: Preserve literal --option-looking text, single/double quotes, newline boundaries, and $(touch ${marker}-${serial}); '@literal "double".`,
      ].join('\n');
      const env = {
        PATH: `${bin}:${f.runtimePath}`,
        XDG_CONFIG_HOME: xdg,
        STEWARD_TEST_PACKAGE: f.raw,
        TEST_PAIR: `fixture-${tool}`,
        EXPECTED_TASK: task,
        HTTP_CAPTURE: http,
        NATIVE_CAPTURE: capture,
        TYPESAFE_API_KEY: 'Inherited-MustNotWin',
        typesafe_api_key: 'Lowercase-MustBeStripped',
        TyPeSaFe_ApI_KeY: 'Mixedcase-MustBeStripped',
        OPENAI_API_KEY: 'SyntheticProviderOnly',
      };
      const result = spawnSync(f.wrappers[effort], ['router', 'start', '--', task], {
        cwd,
        env,
        encoding: 'utf8',
      });
      assert.equal(result.status, 23, result.stderr);
      const prefix =
        tool === 'codex'
          ? ['--model', 'requested-codex', '-c', 'model_provider="openai"']
          : tool === 'pi'
            ? ['--provider', 'openai-codex', '--model', 'requested-pi']
            : ['--model=requested-agy'];
      if (effort === 'high') {
        prefix.push(
          ...(tool === 'codex'
            ? ['-c', 'model_reasoning_effort="high"']
            : tool === 'pi'
              ? ['--thinking', 'high']
              : ['--effort=high']),
        );
      }
      const tail = tool === 'agy' ? [`--prompt-interactive=User task:\n${task}`] : ['--', `User task:\n${task}`];
      assert.deepEqual(lines(capture), [
        {
          tool,
          argv: [...prefix, ...tail],
          cwd,
          keyNames: [],
          provider: 'SyntheticProviderOnly',
        },
      ]);
      assert.equal(lines(http).length, 1);
      assert.equal(lines(http)[0].state.task, task);
      assert.ok(!readFileSync(http, 'utf8').includes(key));
      assert.ok(!readFileSync(capture, 'utf8').includes(key));
      assert.ok(!result.stdout.includes(key));
      assert.ok(!result.stderr.includes(key));
      assert.equal(existsSync(report), false);
      assert.equal(existsSync(join(cwd, `${marker}-${serial}`)), false);
    }
  }

  clear();
  renameSync(join(bin, 'codex'), join(bin, 'codex-disabled'));
  writeFileSync(join(configDir, 'config.json'), readFileSync(f.configs.default));
  const missingTask = 'Unique missing-native binary fallback sentinel';
  const missing = spawnSync(f.wrappers.default, ['router', 'start', '--', missingTask], {
    cwd,
    env: {
      PATH: `${bin}:${f.runtimePath}`,
      XDG_CONFIG_HOME: xdg,
      STEWARD_TEST_PACKAGE: f.raw,
      TEST_PAIR: 'fixture-codex',
      EXPECTED_TASK: missingTask,
      HTTP_CAPTURE: http,
      NATIVE_CAPTURE: capture,
      OPENAI_API_KEY: 'SyntheticProviderOnly',
    },
    encoding: 'utf8',
  });
  assert.equal(missing.status, 1);
  assert.equal(JSON.parse(missing.stdout).reason_code, 'launch_failed');
  assert.equal(lines(http).length, 1);
  assert.equal(lines(http)[0].state.task, missingTask);
  assert.equal(lines(capture).length, 0);
  assert.equal(existsSync(join(cwd, `${marker}-7`)), false);
} finally {
  rmSync(root, { recursive: true, force: true });
}
