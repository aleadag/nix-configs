# Yegge Agent Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Provide opt-in Yegge primary-session configurations for Codex and Claude Code from one declaratively managed prompt.

**Architecture:** Store the platform-neutral orchestration instructions in one Markdown file. Read that prompt into an opt-in Codex root profile and embed the same prompt in a Claude Code custom-agent document that can launch the primary session.

**Tech Stack:** Nix, Home Manager, Codex configuration profiles, Claude Code custom agents, Beads, Jujutsu

## Global Constraints

- The ordinary `codex` and `claude` commands must remain unchanged.
- Users launch Yegge explicitly with `codex --profile yegge` or `claude --agent yegge`.
- Do not add wrapper commands, aliases, permissions, sandbox changes, model overrides, plugins, or packages.
- The shared prompt must use platform-neutral tooling language and defer commit, push, and external-state decisions to active repository and user policy.
- Keep one source of truth for Yegge's behavioral instructions.
- Do not commit or push without explicit user authority under this repository's conservative Beads profile.

---

### Task 1: Add the shared Yegge prompt and native client configurations

**Files:**
- Create: `modules/home-manager/dev/coding-agents/agents/yegge.md`
- Modify: `modules/home-manager/dev/coding-agents/codex.nix`
- Modify: `modules/home-manager/dev/coding-agents/claude-code.nix`

**Interfaces:**
- Consumes: `programs.codex.profiles`, `programs.claude-code.agents`, and the existing `pvg1` Home Manager configuration.
- Produces: `programs.codex.profiles.yegge.developer_instructions :: string` and `programs.claude-code.agents.yegge :: string`.

**Acceptance Criteria:**
- `codex --profile yegge` loads an opt-in root profile whose developer instructions contain the shared Yegge prompt.
- `claude --agent yegge` can load an opt-in custom agent with valid YAML frontmatter and the same shared prompt body.
- Existing default Codex and Claude Code settings, permissions, models, packages, and launch commands are unchanged.
- Targeted lint and a `pvg1` activation-package dry run succeed.

- [ ] **Step 1: Verify the desired Codex root configuration is absent**

Run:

```bash
nix eval --json '.#homeConfigurations.pvg1.config.home.file' --apply 'x: builtins.filter (name: builtins.match ".*yegge.*" name != null) (builtins.attrNames x)'
nix eval --json '.#homeConfigurations.pvg1.config.programs.codex.profiles' --apply 'x: builtins.hasAttr "yegge" x'
```

Expected: the managed-file list contains a Codex `agents/yegge.toml`, while the profile check returns `false`. This demonstrates the configuration does not yet provide the requested root-session behavior.

- [ ] **Step 2: Add the shared platform-neutral prompt**

Create `modules/home-manager/dev/coding-agents/agents/yegge.md` with:

```markdown
# yegge — Orchestrator Agent

> Adapted from the Yegge example agent in `DollarDill/beads-superpowers`.

You are the primary agent for this session. Triage each request, route it to the applicable skills, and coordinate non-trivial work end to end. Let each skill own its detailed workflow and gates instead of restating them. Follow active user, repository, and orchestrator instructions when they are more specific.

## Triage

Route first, then scale the process to the task. This routing guidance never overrides an applicable skill's trigger rules.

- For a quick question, answer directly from grounded evidence.
- For a typo, comment, rename, or obvious single-file fix, make the smallest change, run the obvious check, and verify before claiming completion.
- For a feature, refactor, multi-file change, architectural decision, or production-impacting change, use the full flow below.
- For a research request or an important unknown, use the research-driven-development skill before planning or implementation.
- For a bug, failing test, or unexpected behavior, use systematic-debugging before proposing or implementing a fix.

## Full flow for non-trivial work

1. Research material unknowns with research-driven-development; skip this only when the relevant behavior is already grounded.
2. Design with brainstorming and obtain user approval.
3. Create an implementation plan with writing-plans and obtain user approval.
4. Implement using the approved execution workflow and test-driven-development where code or behavior changes.
5. Review and verify with requesting-code-review and verification-before-completion as applicable.
6. Update human-facing documentation when the shipped behavior requires it.
7. Finish according to the active repository workflow and consent boundaries.

If debugging or review feedback interrupts a step, use the corresponding skill and then resume the flow.

## Always true

- Never implement non-trivial work without an approved design and plan.
- Show fresh evidence before claiming work is done, fixed, or passing.
- Use Beads for durable task tracking whenever the active repository or skills require it.
- Use the platform's available structured-question mechanism for material choices; when unavailable, ask one concise question with clear options.
- Surface tradeoffs and ambiguity. Never silently descope a requirement or weaken a security control.
- Keep changes surgical: every changed line must trace to the request.
- Do not commit, push, publish, merge, or make other consequential external changes unless active instructions authorize them.
- Use subagents only when the user or applicable instructions authorize delegation and the work has genuinely independent parts.

## Session behavior

At the start of an otherwise empty session, greet briefly, confirm readiness, and wait for a task. During work, keep the user informed with concise progress updates. At handoff, report changed files, validation evidence, task status, and any action awaiting authorization.
```

- [ ] **Step 3: Add the Codex root profile**

In the `let` block of `modules/home-manager/dev/coding-agents/codex.nix`, immediately after `mySkills`, add:

```nix
  yeggeInstructions = builtins.readFile ./agents/yegge.md;
```

Inside `programs.codex`, alongside `plugins`, `rules`, and `settings`, add:

```nix
      profiles.yegge.developer_instructions = yeggeInstructions;
```

Remove any managed Codex `agents/yegge.toml`. The profile intentionally configures the root session and inherits all unspecified settings from the base configuration.

- [ ] **Step 4: Add the Claude Code agent**

In the `let` block of `modules/home-manager/dev/coding-agents/claude-code.nix`, add:

```nix
  yeggeInstructions = builtins.readFile ./agents/yegge.md;
```

Inside `programs.claude-code`, alongside `package`, `context`, and `settings`, add:

```nix
      agents.yegge = ''
        ---
        name: yegge
        description: Primary session orchestrator that triages requests and coordinates non-trivial work through the applicable skills.
        model: inherit
        ---

        ${yeggeInstructions}
      '';
```

The Claude Code module will render this as `agents/yegge.md` under its managed configuration directory.

- [ ] **Step 5: Format and lint the changed configuration**

Run:

```bash
just lint modules/home-manager/dev/coding-agents/codex.nix modules/home-manager/dev/coding-agents/claude-code.nix
```

Expected: formatting completes and lint exits successfully without modifying unrelated files.

- [ ] **Step 6: Verify the rendered Codex profile**

Run:

```bash
nix eval --json '.#homeConfigurations.pvg1.config.programs.codex.profiles.yegge'
nix eval --json '.#homeConfigurations.pvg1.config.home.file' --apply 'x: builtins.filter (name: builtins.match ".*yegge.*" name != null) (builtins.attrNames x)'
```

Expected: the profile contains one `developer_instructions` string beginning with `# yegge — Orchestrator Agent`, and the managed-file list contains only Claude Code's `agents/yegge.md` with no Codex custom-agent TOML.

- [ ] **Step 7: Verify the rendered Claude Code agent**

Run:

```bash
nix eval --raw '.#homeConfigurations.pvg1.config.programs.claude-code.agents.yegge'
```

Expected: exit status 0 and output containing the `name: yegge`, `model: inherit`, and `# yegge — Orchestrator Agent` lines.

- [ ] **Step 8: Validate Home Manager integration**

Run:

```bash
nix build '.#homeConfigurations.pvg1.activationPackage' --dry-run
```

Expected: exit status 0 with a valid activation-package dry run.

- [ ] **Step 9: Review scope and prepare the conservative handoff**

Run:

```bash
jj --no-pager diff --git
jj --no-pager st
```

Expected: only the approved spec, plan, shared Yegge prompt, and the two coding-agent modules are changed. Report validation and the proposed commit command, but do not commit or push without explicit user authority.
