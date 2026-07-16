# Yegge agent configuration design

## Context

The coding-agent Home Manager modules already manage Codex and Claude Code declaratively. The requested Yegge agent is an orchestration prompt from `DollarDill/beads-superpowers`, but its example file is written for Claude Code and contains Claude-specific tool names and session-close assumptions.

Codex and Claude Code provide different mechanisms for starting a primary session with custom instructions:

- Codex loads an opt-in root configuration layer with `codex --profile yegge`.
- Claude Code discovers Markdown custom-agent files and can start a primary session with `claude --agent yegge`.

## Goals

- Make Yegge available as an opt-in primary-session configuration for Codex and Claude Code.
- Keep the orchestration behavior consistent between the two clients.
- Manage both configurations through the existing Home Manager modules.
- Preserve repository and session policies, including conservative commit and push behavior.

## Non-goals

- Do not change the default behavior of `codex` or `claude`.
- Do not add wrapper commands or aliases.
- Do not change permissions, sandboxing, models, plugins, or installed packages.
- Do not reproduce Claude-specific tool names in the shared prompt.

## Design

Add one shared prompt body under `modules/home-manager/dev/coding-agents/agents/`. It will adapt the upstream Yegge prompt into platform-neutral primary-session instructions while preserving its core behavior:

- triage quick questions, simple changes, research, and non-trivial work;
- route work through the applicable beads-superpowers skills;
- use Beads for durable task tracking;
- require design, planning, implementation, verification, and finish gates where appropriate;
- keep changes surgical and evidence-backed;
- defer commit, push, and other external-state decisions to active repository and user policy.

The prompt will refer to the platform's available skill and structured-question mechanisms rather than literal Claude Code tool names.

### Codex

`modules/home-manager/dev/coding-agents/codex.nix` will read the shared prompt and configure an opt-in profile:

```nix
programs.codex.profiles.yegge.developer_instructions = yeggeInstructions;
```

Home Manager will render `CODEX_HOME/yegge.config.toml`. The user starts the root session explicitly with:

```console
codex --profile yegge
```

Using a profile is intentional: Yegge is the root orchestrator, while Codex custom-agent files only configure spawned sessions. The profile contains only `developer_instructions`, so normal model, permissions, plugins, and other base settings remain inherited.

### Claude Code

`modules/home-manager/dev/coding-agents/claude-code.nix` will read the same prompt and add a `programs.claude-code.agents.yegge` entry. The generated Markdown will add Claude Code's required YAML frontmatter (`name`, `description`, and `model`) before the shared prompt.

The user starts it explicitly with:

```console
claude --agent yegge
```

The agent will use `model: inherit` and retain the existing Claude Code permissions and settings.

## Safety and compatibility

- The change adds instructions only; it grants no additional tools or permissions.
- Both primary-session configurations are opt-in, so existing sessions and automation remain unchanged.
- Platform-specific serialization stays in the corresponding module, while behavioral instructions have one source of truth.
- Repository, user, and orchestrator instructions remain higher priority than the shared agent prompt.

## Validation

1. Evaluate the rendered Codex Yegge profile, confirm its developer instructions equal the shared prompt, and confirm no Codex Yegge custom-agent file is managed.
2. Evaluate the rendered Claude Code Yegge agent and confirm its frontmatter and shared body.
3. Run targeted lint on both coding-agent modules and the shared prompt where supported.
4. Dry-run the `pvg1` Home Manager activation package to validate generated files and module integration.
