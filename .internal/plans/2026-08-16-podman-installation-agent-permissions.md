# Podman Installation and Agent Permissions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Make platform-owned Podman installation enable narrowly scoped Podman and Docker agent permissions, with safe reads allowed, catastrophic cleanup forbidden, and every other command prompted.

**Architecture:** NixOS keeps `virtualisation.podman.enable` as its source of truth, while nix-darwin gains `nix-darwin.homebrew.podman.enable`. Both integrations set `home-manager.dev.coding-agents.permissions.containers.enable`; the shared permission renderer converts it into separate allow and deny lists.

**Tech Stack:** Nix flakes, nix-darwin, Home Manager, NixOS Podman module, Homebrew, Codex execpolicy, Statix, treefmt

## Global Constraints

- Preserve existing uncommitted work and touch only the approved Podman/Docker scope, spec, and plan.
- Do not manage Docker Desktop, create or start a Podman machine, or own `~/.docker/config.json`.
- Do not automatically allow builds, runs, host mounts, publication, Compose mutations, or lifecycle mutations.
- Remove the unrelated local `corepack` addition.
- Do not commit, push, activate, uninstall Docker Desktop, or sync Beads without explicit authorization.
- Work in the current tree because this corrects existing local changes; create no worktree unless asked.

---

### Task 1: Make platform installation the source of the Home Manager capability

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/default.nix`
- Modify: `modules/home-manager/dev/default.nix`
- Delete: `modules/home-manager/dev/virtualisation.nix`
- Modify: `modules/nix-darwin/homebrew.nix`
- Modify: `modules/nixos/home.nix`
- Modify: `modules/nixos/dev/virtualisation/default.nix`
- Modify: `modules/nixos/system/virtualisation.nix`

**Interfaces:**
- Consumes: final `config.virtualisation.podman.enable`, `config.nix-darwin.homebrew.enable`, and existing system-to-Home-Manager bridges.
- Produces: `home-manager.dev.coding-agents.permissions.containers.enable`, `nix-darwin.homebrew.podman.enable`, and Darwin `DOCKER_HOST`.

**Acceptance Criteria:**
- Darwin conditionally installs `podman`, `podman-compose`, `docker`, and `docker-compose` through a nested option defaulting to Homebrew enablement.
- NixOS derives the capability centrally from final Podman enablement.
- Darwin derives the capability and `DOCKER_HOST` from its Podman option.
- The obsolete Home Manager virtualization option and duplicate NixOS bridge assignments are removed.

- [ ] **Step 1: Prove the approved interface is absent**

```bash
nix eval --json '.#darwinConfigurations.t0.config.nix-darwin.homebrew.podman.enable'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable'
```

Expected: both fail because these options do not exist yet.

- [ ] **Step 2: Define the Home Manager capability**

Extend `options.home-manager.dev.coding-agents` in `modules/home-manager/dev/coding-agents/default.nix`:

```nix
permissions.containers.enable = lib.mkEnableOption "Podman-backed container command permissions";
```

`mkEnableOption` supplies the required `false` default.

- [ ] **Step 3: Remove the obsolete option**

Remove `./virtualisation.nix` from `modules/home-manager/dev/default.nix`, then delete `modules/home-manager/dev/virtualisation.nix`. Preserve every other import.

- [ ] **Step 4: Add Darwin installation ownership**

In `modules/nix-darwin/homebrew.nix`, add `podmanCfg = cfg.podman;` and `homeDirectory = config.users.users.${username}.home;` to `let`, then use:

```nix
options.nix-darwin.homebrew = {
  enable = lib.mkEnableOption "Homebrew config" // {
    default = true;
  };

  podman.enable = lib.mkEnableOption "Podman with Docker-compatible clients" // {
    default = config.nix-darwin.homebrew.enable;
  };
};
```

Within `lib.mkIf cfg.enable`, replace the current bridge and brew list with:

```nix
nix-darwin.home.extraModules = {
  home-manager.dev.coding-agents.permissions.containers.enable = podmanCfg.enable;
  home.sessionVariables.DOCKER_HOST = lib.mkIf podmanCfg.enable (
    "unix://${homeDirectory}/.local/share/containers/podman/machine/podman.sock"
  );
  programs = {
    firefox.package = lib.mkForce null;
    kitty.package = null;
  };
};

homebrew.brews = lib.optionals podmanCfg.enable [
  "docker"
  "docker-compose"
  "podman"
  "podman-compose"
];
```

Keep all casks and remaining Homebrew settings unchanged.

- [ ] **Step 5: Centralize the NixOS bridge**

Add to `nixos.home.extraModules` in `modules/nixos/home.nix`:

```nix
home-manager.dev.coding-agents.permissions.containers.enable =
  config.virtualisation.podman.enable;
```

Remove only the newly added `nixos.home.extraModules` blocks from both NixOS virtualization modules.

- [ ] **Step 6: Verify the interface**

```bash
nix eval --json '.#darwinConfigurations.t0.config.nix-darwin.homebrew.podman.enable'
nix eval --json '.#darwinConfigurations.t0.config.homebrew.brews'
nix eval --raw '.#darwinConfigurations.t0.config.home-manager.users.alexander.home.sessionVariables.DOCKER_HOST'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable'
nix eval --json '.#nixosConfigurations.pvg1-nixos.config.virtualisation.podman.enable'
nix eval --json '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable'
nix eval --json '.#nixosConfigurations.jetson-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable'
```

Expected: Darwin is enabled, contains all four brews, and uses `unix:///Users/alexander/.local/share/containers/podman/machine/podman.sock`; `pvg1-nixos` reports both values as `true`; `jetson-nixos` reports `false`.

- [ ] **Step 7: Review without committing**

```bash
git diff -- modules/home-manager/dev/coding-agents/default.nix modules/home-manager/dev/default.nix modules/home-manager/dev/virtualisation.nix modules/nix-darwin/homebrew.nix modules/nixos/home.nix modules/nixos/dev/virtualisation/default.nix modules/nixos/system/virtualisation.nix
```

Expected: only the approved installation/capability flow changes.

---

### Task 2: Replace broad grants with explicit container allow and deny lists

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/permissions.nix`

**Interfaces:**
- Consumes: `config.home-manager.dev.coding-agents.permissions.containers.enable`.
- Produces: gated `containerAllowedCommands` and `containerDeniedCommands` merged into the existing shared outputs.

**Acceptance Criteria:**
- Read-only Podman and Docker inspection is allowed only when the capability is enabled.
- Catastrophic cleanup is denied only when the capability is enabled.
- Builds, runs, publication, lifecycle changes, and Compose mutations match neither list and prompt.
- No broad `system`, `volume`, `run`, or equivalent parent prefix is allowed.
- `corepack` is absent from this diff.

- [ ] **Step 1: Record the unsafe baseline**

```bash
git diff HEAD -- modules/home-manager/dev/coding-agents/permissions.nix
```

Expected: the current local diff shows broad `podman system`, `podman volume`, and `podman run` grants.

- [ ] **Step 2: Add the capability and exact suffix sets**

Replace `hasPodman` with:

```nix
hasContainers = config.home-manager.dev.coding-agents.permissions.containers.enable or false;
```

Add:

```nix
commonContainerAllowedCommands = [
  "ps"
  "images"
  "inspect"
  "logs"
  "info"
  "version"
  "port"
  "top"
  "stats"
  "container inspect"
  "container ls"
  "image inspect"
  "image ls"
  "network inspect"
  "network ls"
  "volume inspect"
  "volume ls"
  "system df"
];

commonContainerDeniedCommands = [
  "system prune"
  "container prune"
  "image prune"
  "network prune"
  "volume prune"
];
```

- [ ] **Step 3: Build the separate complete lists**

```nix
containerAllowedCommands =
  lib.concatMap
    (runtime: map (command: "${runtime} ${command}") commonContainerAllowedCommands)
    [
      "podman"
      "docker"
    ]
  ++ map (command: "podman ${command}") [
    "pod inspect"
    "pod ps"
    "machine inspect"
    "machine list"
  ]
  ++ [
    "podman-compose --version"
    "docker-compose version"
  ];

containerDeniedCommands =
  lib.concatMap
    (runtime: map (command: "${runtime} ${command}") commonContainerDeniedCommands)
    [
      "podman"
      "docker"
    ]
  ++ map (command: "podman ${command}") [
    "system reset"
    "pod prune"
    "machine reset"
    "machine rm"
  ]
  ++ map (command: "docker ${command}") [
    "builder prune"
    "buildx prune"
  ];
```

- [ ] **Step 4: Gate both outputs and remove unrelated scope**

Append `lib.optionals hasContainers containerAllowedCommands` to `allowedShellCommands`, and append `lib.optionals hasContainers containerDeniedCommands` to `deniedShellCommands`. Remove `corepack` from `nodeCommands`; change no other family.

- [ ] **Step 5: Verify the shared rendered behavior through Claude Code**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.claude-code.settings.permissions.allow' | jq -e 'index("Bash(podman ps:*)") and index("Bash(docker inspect:*)") and (index("Bash(podman run:*)") | not)'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.claude-code.settings.permissions.deny' | jq -e 'index("Bash(podman system reset:*)") and index("Bash(docker system prune:*)")'
nix eval --json '.#nixosConfigurations.jetson-nixos.config.home-manager.users.alexander' --apply 'hm: hm.programs.claude-code.settings.permissions.allow or []' | jq -e 'index("Bash(podman ps:*)") | not'
```

Expected: all commands exit zero.

- [ ] **Step 6: Review without committing**

```bash
git diff --check -- modules/home-manager/dev/coding-agents/permissions.nix
git diff -- modules/home-manager/dev/coding-agents/permissions.nix
```

Expected: only the capability and approved allow/deny policy remain.

---

### Task 3: Verify every renderer and platform boundary

**Files:**
- Verify: files changed by Tasks 1 and 2
- Verify: `.internal/specs/2026-08-16-podman-installation-agent-permissions-design.md`
- Verify: `.internal/plans/2026-08-16-podman-installation-agent-permissions.md`

**Interfaces:**
- Consumes: platform ownership and shared command policy.
- Produces: fresh platform and renderer evidence for allow, forbidden, and prompt states.

**Acceptance Criteria:**
- Formatting, Statix, flake checks, and whitespace checks pass.
- Codex allows inspection, forbids catastrophic cleanup, and leaves mutation unmatched for Podman and Docker.
- Claude Code, OpenCode, and Antigravity CLI contain equivalent patterns.
- Docker Desktop remains installed and unmanaged.

- [ ] **Step 1: Run focused formatting and linting**

```bash
nix fmt -- --ci modules/home-manager/dev/coding-agents/default.nix modules/home-manager/dev/coding-agents/permissions.nix modules/home-manager/dev/default.nix modules/nix-darwin/homebrew.nix modules/nixos/home.nix modules/nixos/dev/virtualisation/default.nix modules/nixos/system/virtualisation.nix
statix check modules/home-manager/dev/coding-agents/default.nix
statix check modules/home-manager/dev/coding-agents/permissions.nix
statix check modules/home-manager/dev/default.nix
statix check modules/nix-darwin/homebrew.nix
statix check modules/nixos/home.nix
statix check modules/nixos/dev/virtualisation/default.nix
statix check modules/nixos/system/virtualisation.nix
```

Expected: formatting makes zero further changes and every lint exits zero.

- [ ] **Step 2: Run platform and flake evaluation**

Repeat Task 1 Step 6, then run `nix flake check`. Expected: targeted values match. If the full check fails, compare the exact `HEAD` revision and record a follow-up only when the same failure predates this change; do not weaken or silently skip the check.

- [ ] **Step 3: Locate generated Codex rules without activation**

```bash
nix build --no-link '.#darwinConfigurations.t0.config.system.build.toplevel'
codex_rules_path=$(nix eval --raw '.#darwinConfigurations.t0.config.home-manager.users.alexander.home.activation.writeCodexRules.data' | sed -n 's|.*install -m 644 \([^ ]*codex-basic.rules\).*|\1|p')
test -n "$codex_rules_path"
test -f "$codex_rules_path"
```

Expected: the build realizes the generated `writeText` store object, both tests exit zero, and live user configuration is untouched.

- [ ] **Step 4: Verify Codex decisions**

```bash
codex execpolicy check --pretty --rules "$codex_rules_path" podman ps
codex execpolicy check --pretty --rules "$codex_rules_path" podman system reset -f
codex execpolicy check --pretty --rules "$codex_rules_path" podman run --privileged -v /:/host alpine
codex execpolicy check --pretty --rules "$codex_rules_path" docker inspect example
codex execpolicy check --pretty --rules "$codex_rules_path" docker system prune -f
codex execpolicy check --pretty --rules "$codex_rules_path" docker build .
```

Expected: inspection is `allow`; reset/prune is `forbidden`; run/build has no matched rules. These checks do not execute container commands.

- [ ] **Step 5: Verify OpenCode and Antigravity renderers**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.opencode.settings.permission.bash' | jq -e '.["podman ps *"].data == "allow" and .["podman system reset *"].data == "deny" and .["*"] == "ask"'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.antigravity-cli.permissions.allow' | jq -e 'index("command(podman ps)") and index("command(docker inspect)")'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.antigravity-cli.permissions.deny' | jq -e 'index("command(podman system reset)") and index("command(docker system prune)")'
```

Expected: all commands exit zero; Claude Code was covered in Task 2.

- [ ] **Step 6: Inspect final scope and hand off host migration separately**

```bash
git diff --check HEAD
git status --short
git diff --stat HEAD
```

Expected: only approved configuration, spec, plan, and Beads metadata are changed. Docker Desktop stays manually installed until a later activation proves Podman-backed Docker compatibility. Do not commit, activate, uninstall, push, or sync without authorization.
