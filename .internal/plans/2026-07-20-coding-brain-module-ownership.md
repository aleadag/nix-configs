# Coding Brain Module Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Move Coding Brain out of the Codex-specific Home Manager module, adopt its renamed upstream API, and keep it enabled by default exactly where Codex is enabled.

**Architecture:** The coding-agents aggregate module imports and owns Coding Brain. A local `coding-brain.enable` option defaults to the sibling Codex option but remains independently overrideable. The flake input retains its `codexctl` identity while its lock pin and Home Manager API move atomically to the renamed `programs.coding-brain` surface.

**Tech Stack:** Nix flakes, Home Manager modules, Jujutsu, Beads, `just lint`

## Global Constraints

- Keep the flake input key and URL named `codexctl`; update only its lock pin.
- Preserve every existing Brain setting value.
- Do not explicitly set `programs.coding-brain.codexHooks.enable`; rely on the upstream default tied to Codex enablement.
- Keep the Coding Brain `mkIf` independent of the aggregate coding-agents `mkIf` so an explicit child override works.
- Do not change unrelated Codex settings, skills, plugins, permissions, packages, or hooks.
- Do not commit, push, or sync Beads/Dolt unless the user explicitly authorizes it.
- Treat `flake.lock`, `default.nix`, and `codex.nix` as one compatibility unit; do not leave the old API paired with the new pin or the new API paired with the old pin.

---

### Task 1: Migrate Coding Brain ownership and upstream API

**Bead:** `nix-configs-o1f.1` (child of implementation epic `nix-configs-o1f`)

**Files:**

- Modify: `flake.lock`
- Modify: `modules/home-manager/dev/coding-agents/default.nix`
- Modify: `modules/home-manager/dev/coding-agents/codex.nix`
- Reference: `.internal/specs/2026-07-20-coding-brain-module-ownership-design.md`

**Acceptance criteria:**

- The `codexctl` input is pinned to an upstream revision exposing the `coding-brain` package and `programs.coding-brain` Home Manager module.
- `default.nix` imports that module, declares the local gate, and owns the unchanged Brain settings.
- `codex.nix` contains neither the upstream import nor a Coding Brain/Codexctl program block.
- `pvg1` evaluates with Coding Brain enabled and the package's main program is `coding-brain`.

#### Step 1: Prove the current pin/API cannot satisfy the target configuration

- [ ] Run:

  ```bash
  nix eval .#homeConfigurations.pvg1.config.programs.coding-brain.enable
  ```

  Expected: evaluation fails because the current locked module does not define `programs.coding-brain`. Record the failure text in the bead notes; this is the red check.

#### Step 2: Update only the Coding Brain upstream input

- [ ] Run:

  ```bash
  nix flake update codexctl
  ```

  Expected: `flake.lock` updates the `codexctl` input and any lock nodes required by that input, without changing unrelated top-level inputs.

- [ ] Inspect the lock diff:

  ```bash
  jj --no-pager diff -- flake.lock
  ```

  Expected: changes are attributable only to the `codexctl` input graph. If unrelated top-level inputs changed, stop and restore only those unrelated lock changes before continuing.

#### Step 3: Move module ownership to the aggregate module

- [ ] Replace `modules/home-manager/dev/coding-agents/default.nix` with:

  ```nix
  {
    config,
    flake,
    lib,
    pkgs,
    ...
  }:

  let
    cfg = config.home-manager.dev.coding-agents;
  in
  {
    imports = [
      ./antigravity-cli.nix
      ./claude-code.nix
      ./codex.nix
      ./mcp.nix
      flake.inputs.codexctl.homeManagerModules.default
    ];

    options.home-manager.dev.coding-agents = {
      enable = lib.mkEnableOption "coding agent config" // {
        default = config.home-manager.dev.enable;
      };

      coding-brain.enable = lib.mkEnableOption "Coding Brain" // {
        default = cfg.codex.enable;
      };
    };

    config = lib.mkMerge [
      (lib.mkIf cfg.enable {
        home.packages = with pkgs; [
          llm-agents.agent-deck
          tmux # requires by agent-deck
          ctx7
        ];
      })

      (lib.mkIf cfg.coding-brain.enable {
        programs.coding-brain = {
          enable = true;
          settings.brain = {
            enabled = true;
            endpoint = "http://localhost:11434/api/generate";
            model = "gemma4:e4b";
            auto = false;
            timeout_ms = 25000;
            terminal_auto_approve_fallback = false;
          };
        };
      })
    ];
  }
  ```

#### Step 4: Remove obsolete ownership from the Codex module

- [ ] Delete this import from `modules/home-manager/dev/coding-agents/codex.nix`:

  ```nix
  imports = [ flake.inputs.codexctl.homeManagerModules.default ];
  ```

- [ ] Delete the complete obsolete block from the same file:

  ```nix
  programs.codexctl = {
    enable = true;
    settings.brain = {
      enabled = true;
      endpoint = "http://localhost:11434/api/generate";
      model = "gemma4:e4b";
      auto = false;
      timeout_ms = 25000;
      terminal_auto_approve_fallback = false;
    };
  };
  ```

- [ ] Do not remove the `flake` argument: the module still reads the `jujutsu-skills` and `obsidian-skills` inputs.

#### Step 5: Make the target evaluation green

- [ ] Run:

  ```bash
  nix eval .#homeConfigurations.pvg1.config.home-manager.dev.coding-agents.coding-brain.enable
  nix eval .#homeConfigurations.pvg1.config.programs.coding-brain.enable
  nix eval --raw .#homeConfigurations.pvg1.config.programs.coding-brain.package.meta.mainProgram
  ```

  Expected output, in order:

  ```text
  true
  true
  coding-brain
  ```

- [ ] Search for stale configuration names:

  ```bash
  rg -n 'programs\.codexctl|codexctl\.homeManagerModules' modules/home-manager/dev/coding-agents
  ```

  Expected: exactly one match, the intentional `codexctl.homeManagerModules` import in `default.nix`; no `programs.codexctl` match.

#### Step 6: Review the atomic diff

- [ ] Run:

  ```bash
  jj --no-pager diff -- flake.lock modules/home-manager/dev/coding-agents/default.nix modules/home-manager/dev/coding-agents/codex.nix
  ```

  Expected: only the input pin/API migration, ownership move, new local option, and unchanged Brain values.

- [ ] If the user has explicitly authorized commits, checkpoint with:

  ```bash
  jj desc -m "✨ feat(coding-agents): move Coding Brain into defaults"
  jj new
  ```

  Otherwise leave the working change uncommitted and report it at handoff.

---

### Task 2: Verify defaults, overrides, hooks, formatting, and activation

**Bead:** `nix-configs-o1f.2` (depends on `nix-configs-o1f.1`)

**Files:**

- Verify: `flake.lock`
- Verify: `modules/home-manager/dev/coding-agents/default.nix`
- Verify: `modules/home-manager/dev/coding-agents/codex.nix`
- Modify only if a verification failure demonstrates that the implementation does not meet the approved design.

**Acceptance criteria:**

- Coding Brain follows Codex by default on both an enabled and disabled host.
- Explicit Coding Brain enablement works while Codex is disabled and does not enable Codex hooks.
- Existing Brain settings are unchanged.
- Targeted lint succeeds and the `pvg1` activation package dry run evaluates successfully.

#### Step 1: Verify the default host matrix

- [ ] Run:

  ```bash
  nix eval --json --impure --expr '
    let
      flake = builtins.getFlake (toString ./.);
    in {
      pvg1 = {
        codex = flake.homeConfigurations.pvg1.config.home-manager.dev.coding-agents.codex.enable;
        codingBrain = flake.homeConfigurations.pvg1.config.home-manager.dev.coding-agents.coding-brain.enable;
        program = flake.homeConfigurations.pvg1.config.programs.coding-brain.enable;
        hooks = flake.homeConfigurations.pvg1.config.programs.coding-brain.codexHooks.enable;
      };
      lckfb = {
        codex = flake.homeConfigurations.lckfb.config.home-manager.dev.coding-agents.codex.enable;
        codingBrain = flake.homeConfigurations.lckfb.config.home-manager.dev.coding-agents.coding-brain.enable;
        program = flake.homeConfigurations.lckfb.config.programs.coding-brain.enable;
        hooks = flake.homeConfigurations.lckfb.config.programs.coding-brain.codexHooks.enable;
      };
    }
  '
  ```

  Expected semantic result:

  ```json
  {
    "pvg1": { "codex": true, "codingBrain": true, "program": true, "hooks": true },
    "lckfb": { "codex": false, "codingBrain": false, "program": false, "hooks": false }
  }
  ```

  Attribute ordering is not significant.

#### Step 2: Verify the independent override

- [ ] Run:

  ```bash
  nix eval --json --impure --expr '
    let
      flake = builtins.getFlake (toString ./.);
      extended = flake.homeConfigurations.lckfb.extendModules {
        modules = [{
          home-manager.dev.coding-agents.coding-brain.enable = true;
        }];
      };
    in {
      codex = extended.config.home-manager.dev.coding-agents.codex.enable;
      codingBrain = extended.config.home-manager.dev.coding-agents.coding-brain.enable;
      program = extended.config.programs.coding-brain.enable;
      hooks = extended.config.programs.coding-brain.codexHooks.enable;
    }
  '
  ```

  Expected semantic result:

  ```json
  { "codex": false, "codingBrain": true, "program": true, "hooks": false }
  ```

  This is the regression check proving that the Coding Brain conditional is not nested under the aggregate coding-agents conditional.

#### Step 3: Verify the migrated settings exactly

- [ ] Run:

  ```bash
  nix eval --json .#homeConfigurations.pvg1.config.programs.coding-brain.settings.brain
  ```

  Expected semantic result:

  ```json
  {
    "auto": false,
    "enabled": true,
    "endpoint": "http://localhost:11434/api/generate",
    "model": "gemma4:e4b",
    "terminal_auto_approve_fallback": false,
    "timeout_ms": 25000
  }
  ```

#### Step 4: Run focused quality gates

- [ ] Run:

  ```bash
  just lint modules/home-manager/dev/coding-agents/default.nix modules/home-manager/dev/coding-agents/codex.nix
  ```

  Expected: exit status 0 with no formatting or Statix errors. If formatting changes either file, repeat the evaluations from Steps 1-3.

- [ ] Run:

  ```bash
  nix build .#homeConfigurations.pvg1.activationPackage --dry-run
  ```

  Expected: exit status 0; Nix reports the derivations that would be built or that the activation package is already available.

#### Step 5: Final review and handoff

- [ ] Run:

  ```bash
  jj --no-pager st
  jj --no-pager diff --stat
  ```

  Expected: the spec/plan and the three implementation files are the only intended repository changes; Beads state may also appear according to repository configuration.

- [ ] Record every validation command and result in the task bead, close both implementation tasks and the implementation epic if all acceptance criteria pass, then close brainstorming bead `nix-configs-g9x`.

- [ ] Do not commit, push, or run Beads/Dolt sync without explicit user authorization. Report changed files, validation evidence, Beads status, and the exact optional next VCS command.
