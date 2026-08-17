# Home Manager Podman Generic-Linux Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Extend `home-manager.dev.podman` to provide native rootless Podman plus socket-activated Docker CLI compatibility on standalone systemd Linux hosts without changing Darwin or NixOS ownership.

**Architecture:** Keep one shared Home Manager module and branch its configuration between Darwin and `targets.genericLinux`. The Linux branch reuses the selected Podman package's user units through `systemd.user.packages`, enables only the packaged rootless socket under `sockets.target`, and leaves NixOS on `virtualisation.podman`.

**Tech Stack:** Nix flakes, Home Manager modules, Podman 5.8.4, systemd user units, Docker CLI, Docker Compose, jq, nixfmt, Statix

## Global Constraints

- Keep `home-manager.dev.podman.enable` as the only repository-specific public option.
- Preserve the Darwin `podman-machine-default`, its host-owned resource specification and `services.podman.useDefaultMachine = false` policy, and its `$TMPDIR` socket behavior exactly.
- Support only standalone Linux configurations with `targets.genericLinux.enable = true` and a working systemd user manager.
- Keep NixOS runtime ownership under `virtualisation.podman`.
- Use the selected Podman package's user units; do not recreate or alter their socket path or service lifetime.
- Enable only the rootless Unix socket. Do not configure TCP exposure, rootful Podman, user lingering, or a permanently enabled API service.
- Default `services.podman.autoUpdate.enable` to `false` on generic Linux while allowing a host override.
- Leave `/etc/subuid`, `/etc/subgid`, `newuidmap`, and `newgidmap` under the host distribution's ownership.
- Do not enable the wrapper on an existing generic-Linux host or activate any Home Manager generation in this task.
- Do not change coding-agent command policy; only derive its existing container capability from this wrapper's enablement.

---

### Task 1: Add the generic-Linux Podman branch and prove platform boundaries

**Files:**
- Modify: `modules/home-manager/dev/podman.nix`
- Modify: `hosts/nix-darwin/t0/default.nix`
- Include: `.internal/research/2026-08-16-home-manager-podman-generic-linux.md`
- Include: `.internal/specs/2026-08-16-home-manager-podman-generic-linux-design.md`
- Include: `.internal/plans/2026-08-16-home-manager-podman-generic-linux.md`
- Test: evaluation-only checks against `homeConfigurations.mbx`, `homeConfigurations.lckfb`, `darwinConfigurations.t0`, and `nixosConfigurations.{pvg1-nixos,jetson-nixos}`

**Interfaces:**
- Consumes: `home-manager.dev.podman.enable`, `targets.genericLinux.enable`, upstream `services.podman`, Home Manager `systemd.user.packages`, and the selected Podman package's `share/systemd/user/{podman.service,podman.socket}` files.
- Produces: a generic-Linux branch with Podman enabled, auto-update disabled by default, Docker clients installed, `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock`, packaged user units exposed, the packaged socket enabled under `sockets.target`, and existing coding-agent container permissions enabled.

**Acceptance Criteria:**
- Enabling the wrapper on `mbx` through `extendModules` evaluates successfully without modifying the host declaration.
- The generic-Linux evaluation installs Podman 5.8.4, Docker CLI, and Docker Compose; disables auto-update by default; exposes the selected Podman package through `systemd.user.packages`; and creates only the socket enablement link.
- The generic-Linux `DOCKER_HOST` is the literal runtime expression `unix://$XDG_RUNTIME_DIR/podman/podman.sock`.
- Explicitly setting `services.podman.autoUpdate.enable = true` overrides the wrapper default.
- Enabling the wrapper on Linux without `targets.genericLinux.enable` fails with the module's supported-platform assertion.
- Darwin `t0` retains its exact machine inventory, resources, packages, `$TMPDIR` socket expression, and agent capability.
- NixOS Podman capability behavior remains enabled on `pvg1-nixos` and disabled on `jetson-nixos`.
- Targeted formatting, Statix, evaluation, build, flake, and diff checks pass without activating a host.

- [ ] **Step 1: Run the generic-Linux evaluation as the failing test**

```bash
nix eval --json '.#homeConfigurations.mbx' --apply '
  hm:
  let
    extended = hm.extendModules {
      modules = [{
        home-manager.dev.podman.enable = true;
      }];
    };
  in {
    service = extended.config.services.podman.enable;
    dockerHost = extended.config.home.sessionVariables.DOCKER_HOST;
  }
'
```

Expected before implementation: evaluation fails because the Darwin-only wrapper assigns the Linux read-only `services.podman.useDefaultMachine` option. The current pinned error includes `The option services.podman.useDefaultMachine is read-only, but it is set multiple times`. This proves the test exercises the current missing platform branch.

- [ ] **Step 2: Implement the smallest cross-platform branch**

Replace `modules/home-manager/dev/podman.nix` with:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.podman;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isGenericLinux = pkgs.stdenv.hostPlatform.isLinux && config.targets.genericLinux.enable;
  podmanPackage = config.services.podman.package;
in
{
  options.home-manager.dev.podman.enable = lib.mkEnableOption "Podman development environment";

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = isDarwin || isGenericLinux;
          message = "home-manager.dev.podman is supported only on Darwin or generic Linux";
        }
      ];

      services.podman.enable = true;

      home.packages = with pkgs; [
        docker-client
        docker-compose
      ];

      home-manager.dev.coding-agents.permissions.containers.enable = true;
    }

    (lib.mkIf isDarwin {
      assertions = [
        {
          assertion = builtins.hasAttr "podman-machine-default" config.services.podman.machines;
          message = "home-manager.dev.podman requires services.podman.machines.podman-machine-default";
        }
      ];

      home.sessionVariables.DOCKER_HOST = "unix://$TMPDIR/podman/podman-machine-default-api.sock";
    })

    (lib.mkIf isGenericLinux {
      services.podman.autoUpdate.enable = lib.mkDefault false;

      systemd.user.packages = [ podmanPackage ];
      xdg.configFile."systemd/user/sockets.target.wants/podman.socket".source =
        "${podmanPackage}/share/systemd/user/podman.socket";

      home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    })
  ]);
}
```

Do not add another repository option, a custom service definition, a host enablement, an activation script, or privileged host setup.

- [ ] **Step 3: Verify the generic-Linux result and host override**

```bash
nix eval --json '.#homeConfigurations.mbx' --apply '
  hm:
  let
    extended = hm.extendModules {
      modules = [{
        home-manager.dev.podman.enable = true;
      }];
    };
    cfg = extended.config;
    podmanPackage = cfg.services.podman.package;
  in {
    service = cfg.services.podman.enable;
    autoUpdate = cfg.services.podman.autoUpdate.enable;
    podmanVersion = podmanPackage.version;
    packages = map (package: package.pname or package.name) cfg.home.packages;
    dockerHost = cfg.home.sessionVariables.DOCKER_HOST;
    unitPackage = builtins.elem podmanPackage cfg.systemd.user.packages;
    socketSource = toString cfg.xdg.configFile."systemd/user/sockets.target.wants/podman.socket".source;
    expectedSocketSource = "${podmanPackage}/share/systemd/user/podman.socket";
    declaredServices = builtins.attrNames cfg.systemd.user.services;
    declaredSockets = builtins.attrNames cfg.systemd.user.sockets;
    containerPermissions = cfg.home-manager.dev.coding-agents.permissions.containers.enable;
  }
' | jq -e '
  .service == true and
  .autoUpdate == false and
  .podmanVersion == "5.8.4" and
  (.packages | index("podman")) and
  (.packages | index("docker")) and
  (.packages | index("docker-compose")) and
  .dockerHost == "unix://$XDG_RUNTIME_DIR/podman/podman.sock" and
  .unitPackage == true and
  .socketSource == .expectedSocketSource and
  (.declaredServices | index("podman") | not) and
  (.declaredSockets | index("podman") | not) and
  .containerPermissions == true
'

nix eval --json '.#homeConfigurations.mbx' --apply '
  hm:
  let
    extended = hm.extendModules {
      modules = [{
        home-manager.dev.podman.enable = true;
        services.podman.autoUpdate.enable = true;
      }];
    };
  in extended.config.services.podman.autoUpdate.enable
' | jq -e '. == true'
```

Expected: both `jq` checks exit zero. Empty `systemd.user.services.podman` and `systemd.user.sockets.podman` declarations prove the wrapper links the selected package's units instead of replacing them.

- [ ] **Step 4: Verify the unsupported-Linux assertion**

```bash
if nix eval --json '.#homeConfigurations.lckfb' --apply '
  hm:
  let
    extended = hm.extendModules {
      modules = [{
        home-manager.dev.podman.enable = true;
      }];
    };
  in extended.activationPackage.drvPath
' 2> /tmp/nix-configs-podman-unsupported.log; then
  echo 'unsupported Linux configuration unexpectedly evaluated' >&2
  exit 1
fi

rg -F 'home-manager.dev.podman is supported only on Darwin or generic Linux' \
  /tmp/nix-configs-podman-unsupported.log
```

Expected: the evaluation fails and `rg` finds the specific assertion message. The temporary log contains only evaluation output and may be left under `/tmp`.

- [ ] **Step 5: Prove Darwin behavior is unchanged**

```bash
nix eval --json '.#darwinConfigurations.t0.config.home-manager.users.alexander' --apply '
  hm: {
    devPodman = hm.home-manager.dev.podman.enable;
    service = hm.services.podman.enable;
    useDefaultMachine = hm.services.podman.useDefaultMachine;
    machineNames = builtins.attrNames hm.services.podman.machines;
    machine = hm.services.podman.machines.podman-machine-default;
    podmanVersion = hm.services.podman.package.version;
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
  (.packages | index("podman")) and
  (.packages | index("docker")) and
  (.packages | index("docker-compose")) and
  .dockerHost == "unix://$TMPDIR/podman/podman-machine-default-api.sock" and
  .containerPermissions == true
'
```

Expected: `jq` exits zero. This command evaluates configuration only; it must not activate Home Manager or inspect the live machine.

- [ ] **Step 6: Prove NixOS ownership and permission behavior are unchanged**

```bash
test "$(nix eval --json '.#nixosConfigurations.pvg1-nixos.config.virtualisation.podman.enable')" = true
test "$(nix eval --json '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable')" = true
test "$(nix eval --json '.#nixosConfigurations.jetson-nixos.config.virtualisation.podman.enable')" = false
test "$(nix eval --json '.#nixosConfigurations.jetson-nixos.config.home-manager.users.alexander.home-manager.dev.coding-agents.permissions.containers.enable')" = false
```

Expected: all four checks exit zero. Do not enable `home-manager.dev.podman` inside either NixOS configuration.

- [ ] **Step 7: Run formatting, linting, builds, and repository checks**

```bash
nix fmt -- --ci modules/home-manager/dev/podman.nix hosts/nix-darwin/t0/default.nix
statix check modules/home-manager/dev/podman.nix
statix check hosts/nix-darwin/t0/default.nix
git diff --check HEAD

nix build --no-link '.#homeConfigurations.mbx.activationPackage'
nix build --no-link '.#darwinConfigurations.t0.config.system.build.toplevel'
nix flake check

git status --short
git diff --stat HEAD
git diff -- modules/home-manager/dev/podman.nix hosts/nix-darwin/t0/default.nix
```

Expected: formatting, Statix, both builds, and flake checks exit zero. The diff contains the Podman module, the required `t0` Darwin host-ownership correction, and the approved research, design, and plan artifacts. If the full flake check exposes an unrelated pre-existing failure, record the exact command and error without weakening the targeted evaluations or absorbing an unrelated fix.

- [ ] **Step 8: Commit the reviewed implementation atomically**

After the user has authorized committing the implementation:

```bash
git add \
  modules/home-manager/dev/podman.nix \
  hosts/nix-darwin/t0/default.nix \
  .internal/research/2026-08-16-home-manager-podman-generic-linux.md \
  .internal/specs/2026-08-16-home-manager-podman-generic-linux-design.md \
  .internal/plans/2026-08-16-home-manager-podman-generic-linux.md

git diff --cached --check
git diff --cached --stat
git commit -m '✨ feat(podman): support generic Linux via Home Manager'
```

Expected: one scoped commit containing the module extension and its approved design evidence. Do not push, activate a host, or alter the live Podman runtime.
