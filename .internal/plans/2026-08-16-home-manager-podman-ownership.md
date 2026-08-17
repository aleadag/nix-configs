# Home Manager Podman Ownership Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Move Darwin Podman, Docker CLI, Compose, and the single manually-started Podman machine from Homebrew ownership to a host-configurable Home Manager `services.podman` integration without activating the configuration or deleting live VM state.

**Architecture:** A new `modules/home-manager/dev/podman.nix` module owns service enablement, Nix client packages, shell socket routing, and the existing coding-agent capability. Darwin hosts keep machine resources in the upstream typed `services.podman.machines` option; `t0` declares one rootless, non-auto-starting `podman-machine-default`, while the nix-darwin Homebrew module drops all container formula ownership.

**Tech Stack:** Nix flakes, Home Manager 26.05 `services.podman`, nix-darwin, Nixpkgs Podman 5.8.4, Docker CLI, Docker Compose, Statix, treefmt, Codex execpolicy

## Global Constraints

- Do not activate Home Manager or nix-darwin, stop or remove the existing Podman machine, uninstall Homebrew formulas, or mutate live container state during implementation.
- Do not preserve the existing VM image cache; any containers or named volumes found before cutover block deletion until preservation is separately designed and approved.
- Keep `podman-machine-default` rootless and manually started with `autoStart = false`.
- Use the repository-pinned Podman 5.8.4; do not add a Podman package override.
- Install `pkgs.docker-client` and `pkgs.docker-compose`; do not install `podman-compose`, Docker Desktop, a Docker daemon, or `podman-mac-helper`.
- Scope `DOCKER_HOST` to shells and terminal-launched agents through `$TMPDIR`; do not manage GUI application environments or mutable `~/.docker/config.json`.
- Do not manage registry authentication or credentials.
- Do not claim to pin the VM provider; Home Manager does not expose it, although pinned Podman 5.8.4 currently defaults to AppleHV on Darwin.
- Preserve the existing NixOS Podman ownership and cross-agent allow, deny, and prompt policy.
- Touch only the files named in this plan and documentation required by review findings.
- Commit only with explicit authority from the active user or repository profile; when authorized, include `Bead: nix-configs-gbs` in the commit body.

---

## Task Dependencies

Task 2 depends on Task 1. No implementation task depends on or authorizes the separately gated live cutover.

---

### Task 1: Add the reusable Home Manager Podman module

**Files:**
- Create: `modules/home-manager/dev/podman.nix`
- Modify: `modules/home-manager/dev/default.nix`

**Interfaces:**
- Consumes: Home Manager `services.podman`, `home.packages`, `home.sessionVariables`, and `home-manager.dev.coding-agents.permissions.containers.enable`.
- Produces: `home-manager.dev.podman.enable`; when enabled, a Darwin-only Podman service with `useDefaultMachine = false`, Nix Docker clients, shell-scoped `DOCKER_HOST`, and container-agent capability.

**Acceptance Criteria:**
- `home-manager.dev.podman.enable` exists and defaults to false.
- Enabling it on Darwin enables `services.podman`, disables the implicit default machine, installs `docker-client` and `docker-compose`, omits `podman-compose`, enables container-agent permissions, and sets the expected `$TMPDIR` socket.
- Enabling it requires a host-declared `podman-machine-default` and rejects non-Darwin platforms.
- Importing the module while disabled changes no current host behavior.

- [ ] **Step 1: Prove the repository option is absent**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.home-manager.dev.podman.enable'
```

Expected: evaluation fails because `home-manager.dev.podman.enable` is not defined.

- [ ] **Step 2: Create the minimal Home Manager module**

Create `modules/home-manager/dev/podman.nix` with exactly this ownership boundary:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.podman;
in
{
  options.home-manager.dev.podman.enable = lib.mkEnableOption "Podman development environment";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "home-manager.dev.podman is supported only on Darwin";
      }
      {
        assertion = builtins.hasAttr "podman-machine-default" config.services.podman.machines;
        message = "home-manager.dev.podman requires services.podman.machines.podman-machine-default";
      }
    ];

    services.podman = {
      enable = true;
      useDefaultMachine = false;
    };

    home = {
      packages = with pkgs; [
        docker-client
        docker-compose
      ];

      sessionVariables.DOCKER_HOST = "unix://$TMPDIR/podman/podman-machine-default-api.sock";
    };

    home-manager.dev.coding-agents.permissions.containers.enable = true;
  };
}
```

- [ ] **Step 3: Import the module without enabling it**

Add only `./podman.nix` to `modules/home-manager/dev/default.nix`:

```nix
  imports = [
    ./coding-agents
    ./go.nix
    ./httpie.nix
    ./nix.nix
    ./node.nix
    ./ollama.nix
    ./podman.nix
    ./python.nix
  ];
```

- [ ] **Step 4: Verify the new option is present but inert**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.home-manager.dev.podman.enable'
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.services.podman.enable'
nix eval --json '.#darwinConfigurations.t0.config.homebrew.brews' --apply 'map (brew: brew.name)'
```

Expected output:

```text
false
false
["docker","docker-compose","podman","podman-compose"]
```

This proves the reusable module is imported without changing the current host before Task 2.

- [ ] **Step 5: Format and lint the isolated module change**

```bash
nix fmt -- --ci modules/home-manager/dev/podman.nix modules/home-manager/dev/default.nix
statix check modules/home-manager/dev/podman.nix
statix check modules/home-manager/dev/default.nix
git diff --check -- modules/home-manager/dev/podman.nix modules/home-manager/dev/default.nix
```

Expected: all commands exit zero and formatting makes no further changes.

- [ ] **Step 6: Commit only if explicitly authorized**

If the execution session has commit authority:

```bash
git add modules/home-manager/dev/podman.nix modules/home-manager/dev/default.nix
git commit -m '✨ feat(podman): add Home Manager integration' -m 'Bead: nix-configs-gbs'
```

Otherwise leave the reviewed changes uncommitted and report the proposed commit.

---

### Task 2: Move `t0` and client ownership from Homebrew to Home Manager

**Files:**
- Modify: `hosts/nix-darwin/t0/default.nix`
- Modify: `modules/nix-darwin/homebrew.nix`
- Verify: `modules/home-manager/dev/podman.nix`
- Verify unchanged: `modules/nixos/home.nix`
- Verify unchanged: `modules/home-manager/dev/coding-agents/permissions.nix`

**Interfaces:**
- Consumes: `home-manager.dev.podman.enable` from Task 1 and upstream `services.podman.machines.<name>`.
- Produces: a `t0` Home Manager configuration with one explicitly specified `podman-machine-default`; no Darwin Homebrew container formulas; unchanged NixOS and coding-agent policy behavior.

**Acceptance Criteria:**
- `t0` enables the Home Manager Podman integration and declares exactly one machine with 4 CPUs, 8192 MiB memory, 100 GiB disk, rootless mode, `autoStart = false`, and the approved host mounts.
- No Podman launchd watchdog is generated.
- Home Manager supplies Podman 5.8.4, Docker CLI, and `docker-compose`, while `podman-compose` is absent.
- The Homebrew Podman option and all four container formulas are removed.
- `DOCKER_HOST` is the literal Home Manager session expression `unix://$TMPDIR/podman/podman-machine-default-api.sock` and expands when its generated shell script is sourced.
- `t0` container-agent permissions remain enabled; `pvg1-nixos` remains enabled and `jetson-nixos` remains disabled.
- Builds and evaluations do not activate the configuration or mutate the live Podman machine.

- [ ] **Step 1: Capture the failing pre-change ownership assertions**

```bash
test "$(nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.home-manager.dev.podman.enable')" = false
test "$(nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.services.podman.enable')" = false
nix eval --json '.#darwinConfigurations.t0.config.homebrew.brews' --apply 'map (brew: brew.name)' | jq -e '
  index("docker") and
  index("docker-compose") and
  index("podman") and
  index("podman-compose")
'
```

Expected: all commands exit zero, proving `t0` still uses the old Homebrew ownership before this task.

- [ ] **Step 2: Declare the complete `t0` machine specification**

Within `nix-darwin.home.extraModules` in `hosts/nix-darwin/t0/default.nix`, keep existing settings and add:

```nix
      home-manager.dev.podman.enable = true;

      services.podman.machines.podman-machine-default = {
        autoStart = false;
        cpus = 4;
        diskSize = 100;
        memory = 8192;
        rootful = false;
        volumes = [
          "/Users:/Users"
          "/private:/private"
          "/var/folders:/var/folders"
        ];
      };
```

Do not add `services.podman.enable` or `useDefaultMachine` to the host; the shared module owns those values.

- [ ] **Step 3: Remove Darwin Homebrew container ownership**

Reduce `modules/nix-darwin/homebrew.nix` to the unrelated Homebrew integration:

```nix
{ config, lib, ... }:

let
  cfg = config.nix-darwin.homebrew;
  inherit (config.nix-darwin.home) username;
in
{
  options.nix-darwin.homebrew.enable = lib.mkEnableOption "Homebrew config" // {
    default = true;
  };

  config = lib.mkIf cfg.enable {
    nix-darwin.home.extraModules.programs = {
      firefox.package = lib.mkForce null;
      kitty.package = null;
    };

    homebrew = {
      enable = true;
      casks = [
        "domzilla-caffeine"
        "feishu"
        "firefox"
        "google-chrome"
        "kitty"
        "linearmouse"
        "microsoft-edge"
      ];
    };

    home-manager.users.${username}.home-manager.darwin.homebrew = {
      enable = true;
      inherit (config.homebrew) prefix;
    };
  };
}
```

Remove only the old nested Podman option, its Home Manager permission/socket bridge, and its four conditional brews.

- [ ] **Step 4: Verify ownership and the exact host machine values**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander' --apply '
  hm: {
    devPodman = hm.home-manager.dev.podman.enable;
    service = hm.services.podman.enable;
    useDefaultMachine = hm.services.podman.useDefaultMachine;
    machineNames = builtins.attrNames hm.services.podman.machines;
    machine = hm.services.podman.machines.podman-machine-default;
    podmanVersion = hm.services.podman.package.version;
    launchdAgents = builtins.attrNames hm.launchd.agents;
    packages = map (package: package.pname or package.name) hm.home.packages;
    dockerHost = hm.home.sessionVariables.DOCKER_HOST;
    containerPermissions = hm.home-manager.dev.coding-agents.permissions.containers.enable;
  }
' | jq -e '
  .devPodman == true and
  .service == true and
  .useDefaultMachine == false and
  .machineNames == ["podman-machine-default"] and
  .machine.autoStart == false and
  .machine.cpus == 4 and
  .machine.diskSize == 100 and
  .machine.memory == 8192 and
  .machine.rootful == false and
  .machine.volumes == ["/Users:/Users", "/private:/private", "/var/folders:/var/folders"] and
  .podmanVersion == "5.8.4" and
  ([.launchdAgents[] | select(startswith("podman-machine-"))] | length) == 0 and
  (.packages | index("podman")) and
  (.packages | index("docker")) and
  (.packages | index("docker-compose")) and
  ((.packages | index("podman-compose")) | not) and
  .dockerHost == "unix://$TMPDIR/podman/podman-machine-default-api.sock" and
  .containerPermissions == true
'
```

Expected: `jq` exits zero. This is evaluation only and must not activate Home Manager.

- [ ] **Step 5: Verify Homebrew no longer owns the clients**

```bash
nix eval --json '.#darwinConfigurations.t0.config.homebrew.brews' --apply 'map (brew: brew.name)' | jq -e '
  (index("docker") | not) and
  (index("docker-compose") | not) and
  (index("podman") | not) and
  (index("podman-compose") | not)
'

if nix eval --json '.#darwinConfigurations.t0.config.nix-darwin.homebrew.podman.enable'; then
  echo 'obsolete nix-darwin.homebrew.podman option still exists' >&2
  exit 1
fi
```

Expected: the `jq` check exits zero and the obsolete-option evaluation fails.

- [ ] **Step 6: Verify `$TMPDIR` remains a runtime shell reference**

```bash
session_vars_package=$(nix build --no-link --print-out-paths \
  '.#darwinConfigurations.t0.config.home-manager.users.alexander.home.sessionVariablesPackage')

rg -F 'export DOCKER_HOST="unix://$TMPDIR/podman/podman-machine-default-api.sock"' \
  "$session_vars_package/etc/profile.d/hm-session-vars.sh"
```

Expected: `rg` finds exactly the generated export. Do not source the file into the implementation shell as a substitute for post-cutover validation.

- [ ] **Step 7: Prove NixOS and agent policy behavior is unchanged**

```bash
test "$(nix eval --json '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable')" = true
test "$(nix eval --json '.#nixosConfigurations.jetson-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable')" = false

nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.claude-code.settings.permissions.allow' \
  | jq -e 'index("Bash(podman ps:*)") and index("Bash(docker inspect:*)") and (index("Bash(podman run:*)") | not)'

nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.claude-code.settings.permissions.deny' \
  | jq -e 'index("Bash(podman system reset:*)") and index("Bash(docker system prune:*)")'

nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.opencode.settings.permission.bash' \
  | jq -e '.["podman ps *"].data == "allow" and .["podman system reset *"].data == "deny" and .["*"] == "ask"'

nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.antigravity-cli.permissions.allow' \
  | jq -e 'index("command(podman ps)") and index("command(docker inspect)")'

nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander.programs.antigravity-cli.permissions.deny' \
  | jq -e 'index("command(podman system reset)") and index("command(docker system prune)")'
```

Expected: every command exits zero. These checks render policy only and do not execute Podman or Docker commands.

- [ ] **Step 8: Build without activation and run repository quality gates**

```bash
nix fmt -- --ci \
  modules/home-manager/dev/podman.nix \
  modules/home-manager/dev/default.nix \
  hosts/nix-darwin/t0/default.nix \
  modules/nix-darwin/homebrew.nix

statix check modules/home-manager/dev/podman.nix
statix check modules/home-manager/dev/default.nix
statix check hosts/nix-darwin/t0/default.nix
statix check modules/nix-darwin/homebrew.nix

nix build --no-link '.#darwinConfigurations.t0.config.system.build.toplevel'
nix flake check
git diff --check HEAD
git status --short
git diff --stat HEAD
```

Expected: formatting and linting exit zero, the `t0` system builds without activation, flake checks pass, and the final diff contains only the approved Podman ownership files plus authorized planning artifacts. If a full flake check exposes a pre-existing unrelated failure, capture its exact command and error; do not weaken this plan's targeted checks or absorb an unrelated fix.

- [ ] **Step 9: Verify the live VM remains untouched**

```bash
podman machine inspect podman-machine-default --format '{{.Name}} {{.State}} {{.Resources.CPUs}} {{.Resources.Memory}} {{.Resources.DiskSize}} {{.Rootful}}'
podman ps -a --format json | jq -e 'length == 0'
podman volume ls --format json | jq -e 'length == 0'
```

Expected: the existing machine still exists with its pre-cutover state, and no implementation command has stopped, removed, or recreated it. If containers or named volumes now exist, record that cutover is blocked.

- [ ] **Step 10: Commit only if explicitly authorized**

If the execution session has commit authority:

```bash
git add hosts/nix-darwin/t0/default.nix modules/nix-darwin/homebrew.nix
git commit -m '♻️ refactor(podman): move Darwin ownership to Home Manager' -m 'Bead: nix-configs-gbs'
```

Otherwise leave the reviewed changes uncommitted and report the proposed commit.

## Separately Authorized Cutover

The implementation plan ends before this section. Do not execute these operations merely because the source changes are approved.

At a later cutover, first rerun the read-only checks from Task 2 Step 9. Also verify that `brew uses --installed python@3.14` still reports only `podman-compose`; if another installed formula now uses that Python, preserve it. If the machine still contains no containers or named volumes, warn that the next operation erases the VM disk and image cache, uninstalls the four Homebrew container clients and their now-unused Python, and removes the root-owned `podman-mac-helper` socket. Obtain immediate explicit confirmation for that complete destructive scope. Only then:

```bash
podman machine stop podman-machine-default
podman machine rm podman-machine-default
sudo podman-mac-helper uninstall
brew uninstall docker docker-compose podman podman-compose
if test -z "$(brew uses --installed python@3.14)"; then
  brew uninstall python@3.14
else
  brew uses --installed python@3.14
fi
nix run '.#darwinActivations/t0' --accept-flake-config
exec zsh -l
```

Continue validation in that fresh login shell so command lookup and Home Manager session variables cannot retain the Homebrew environment:

```bash
rehash
for client in podman docker docker-compose; do
  case "$(command -v "$client")" in
    /nix/store/*|"$HOME"/.nix-profile/bin/*|/etc/profiles/per-user/"$USER"/bin/*) ;;
    *) echo "$client does not resolve to the Nix store or a Nix profile" >&2; exit 1 ;;
  esac
done
test "$DOCKER_HOST" = "unix://$TMPDIR/podman/podman-machine-default-api.sock"
test ! -e /var/run/docker.sock
test ! -L /var/run/docker.sock
test ! -e "/Library/LaunchDaemons/com.github.containers.podman.helper-$USER.plist"
if brew list --formula | rg -x 'docker|docker-compose|podman|podman-compose'; then
  echo 'Homebrew container formula still installed' >&2
  exit 1
fi
podman machine start podman-machine-default
podman machine inspect podman-machine-default
podman info
docker ps
docker-compose ls
podman compose version
podman compose ls
```

Post-cutover acceptance requires the recreated rootless machine to have 4 CPUs, 8192 MiB memory, a 100 GiB disk, the approved mounts, no Podman launchd watchdog, and working Nix-managed Podman/Docker/Compose clients through the forwarded `$TMPDIR` socket. The four Homebrew formulas and global `/var/run/docker.sock` helper must be absent. Homebrew Python 3.14 must also be absent if no newly installed formula depends on it. If the preflight discovers containers or named volumes, stop before deletion and create a preservation design.

If activation fails after deletion, restore and activate the previous source configuration to reinstall the Homebrew clients. Recreate and start a Homebrew-managed machine manually if required, run `sudo podman-mac-helper install`, and start a fresh login shell. Verify that `/var/run/docker.sock` is a live symlink and that `docker ps` and `docker-compose ls` connect before treating rollback as complete. Alternatively, recreate the declared machine with the Nix Podman client and continue repairing the new configuration. The image cache is not restored; this rollback remains valid only while no unique container or named-volume state exists.
