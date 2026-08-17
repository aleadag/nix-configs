# Home Manager Podman ownership on Darwin design

## Context

The current Darwin configuration installs `podman`, `podman-compose`, `docker`, and `docker-compose` through Homebrew under `nix-darwin.homebrew.podman.enable`. Homebrew `podman-compose` directly depends on Homebrew Python, which introduces another shared Python version and conflicts with the repository's preference for isolated, declarative package ownership.

The existing Podman design deliberately leaves Podman machine creation and startup outside Home Manager. That decision must change to use Home Manager's Darwin `services.podman` module: the service owns the complete Podman machine inventory, generated container configuration, and optional launchd lifecycle. This document supersedes only the Darwin installation and machine-ownership portions of `.internal/specs/2026-08-16-podman-installation-agent-permissions-design.md`. Its NixOS and agent-permission decisions remain in force.

The current machine inventory contains one running rootless AppleHV machine named `podman-machine-default`, configured with 4 CPUs, 8192 MiB memory, and a 100 GiB disk. At design time it contains no containers or named volumes; only re-downloadable images and the default Podman network are present.

## Goals

- Move Darwin Podman, Docker CLI, and Compose client ownership from Homebrew to Nix and Home Manager.
- Use Home Manager `services.podman` as the authoritative owner of the complete Darwin Podman machine inventory.
- Let each Darwin host declare its complete machine specification through the upstream typed `services.podman.machines` option.
- Recreate `podman-machine-default` cleanly so Home Manager's generated container configuration is mounted into the VM.
- Preserve Docker-compatible CLI and Compose workflows without installing Python-backed `podman-compose`.
- Keep machine startup manual.
- Preserve the existing container-agent permission policy without broadening authorization.

## Non-goals

- Preserve the existing VM's image cache.
- Preserve containers or named volumes discovered after this design; their presence blocks deletion until a separate preservation procedure is approved.
- Install Docker Desktop, a Docker daemon, or `podman-mac-helper`.
- Make Docker compatibility available to GUI applications or processes that do not source Home Manager session variables.
- Manage registry authentication or mutable `~/.docker/config.json`.
- Override the repository's pinned Podman package to match Homebrew's version.
- Change NixOS Podman ownership or the existing cross-agent container permission policy.
- Activate the configuration or delete the current VM as part of implementation.

## Ownership and module boundaries

Create `modules/home-manager/dev/podman.nix` and import it from `modules/home-manager/dev/default.nix`. The module owns the Home Manager integration because Home Manager supplies the Podman service, user packages, shell environment, and coding-agent capability.

The module defines one repository option:

```nix
home-manager.dev.podman.enable
```

When enabled, the module:

- asserts that the host platform is Darwin;
- enables `services.podman`;
- sets `services.podman.useDefaultMachine = false` so Home Manager does not synthesize its implicit auto-starting default machine;
- installs the Nix Docker CLI and `docker-compose` packages alongside the Podman package supplied by `services.podman`;
- omits `podman-compose`;
- enables `home-manager.dev.coding-agents.permissions.containers.enable`;
- configures shell-scoped Docker compatibility for the explicitly named `podman-machine-default` socket.

The module does not duplicate or alias Home Manager's machine option schema. Each host uses the upstream `services.podman.machines` option directly. The module asserts that `podman-machine-default` is present when enabled because the shell socket path depends on that stable name.

Remove Podman ownership from `modules/nix-darwin/homebrew.nix`: delete the nested `nix-darwin.homebrew.podman` option, its permission and socket bridge, and the four conditional container formulas. Unrelated Homebrew casks and integration remain unchanged.

## Host configuration

`hosts/nix-darwin/t0/default.nix` enables the new module through the existing `nix-darwin.home.extraModules` bridge and declares:

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

The host owns every machine-specific value. A future Darwin host may choose different resources and mounts without changing the shared module, but it must declare the stable `podman-machine-default` name while the shared Docker socket convention depends on it.

Home Manager's current machine schema does not expose the VM provider. With the pinned Podman 5.8.4 package, a newly created Darwin machine defaults to AppleHV. A future Podman update may change that default; the configuration must not claim provider pinning that the upstream option cannot enforce.

## Package and Compose behavior

`services.podman` supplies the pinned Nixpkgs Podman package, currently version 5.8.4. The development module adds the Nix Docker CLI and `docker-compose`. It does not add `podman-compose`, eliminating its Python runtime from this toolchain.

`podman compose` delegates to an external Compose provider. With `docker-compose` installed and `podman-compose` absent, it selects `docker-compose`. The standalone `docker` and `docker-compose` commands remain available for existing workflows.

The temporary Podman downgrade from Homebrew 6.1.0 to pinned Nixpkgs 5.8.4 is accepted. Normal flake updates, rather than a package override in this module, own future Podman upgrades.

## Docker socket flow

The pinned Nixpkgs Darwin Podman build does not install `podman-mac-helper`, so it does not create `/var/run/docker.sock`. When `podman-machine-default` is running, Podman forwards its API socket to:

```text
$TMPDIR/podman/podman-machine-default-api.sock
```

The module sets:

```text
DOCKER_HOST=unix://$TMPDIR/podman/podman-machine-default-api.sock
```

Home Manager session variables support POSIX runtime variable references, so `$TMPDIR` expands when the generated session-variable script is sourced. This scope intentionally covers interactive shells and terminal-launched coding agents, not arbitrary GUI applications.

Because `autoStart = false`, the socket does not exist until the user manually starts the machine. Podman and Docker clients returning ordinary connection errors before startup is expected behavior.

## Machine lifecycle

Home Manager owns the complete Podman machine inventory. `services.podman.useDefaultMachine = false` and the host's explicit `services.podman.machines` declaration ensure that only the declared machine is managed.

`autoStart = false` prevents Home Manager from generating a Podman launchd watchdog. The user starts and stops the machine explicitly with `podman machine start` and `podman machine stop`.

Home Manager creates a declared machine only when a machine with the same name does not exist. It does not reconcile resource changes onto an existing VM. Later changes to CPU, memory, disk, rootful mode, or volumes therefore require a separately approved destroy-and-recreate operation.

Home Manager stops and force-removes any Podman machine that is not in the declared set during activation. Adding, renaming, or removing machine declarations is consequently a destructive lifecycle decision and requires the same preservation and confirmation discipline as the initial migration.

## Migration procedure

Implementation changes and verifies configuration only. It must not activate Home Manager, stop the machine, or delete the VM.

At a separately authorized cutover:

1. Re-inspect `podman-machine-default` immediately before deletion.
2. Confirm that it still contains no containers or named volumes. If either exists, stop and design preservation before proceeding.
3. Verify that Homebrew Python 3.14 is still used only by `podman-compose`; preserve it if another installed formula has begun to depend on it.
4. Warn that deleting the VM erases its disk and cached images, and that the cutover also removes the four Homebrew container clients, their now-unused Python, and the root-owned `podman-mac-helper` socket. Obtain immediate explicit confirmation for that complete destructive scope.
5. Stop and remove the Homebrew-created `podman-machine-default`.
6. Uninstall `podman-mac-helper` while the Homebrew Podman binary is still available, then uninstall the four Homebrew container formulas and Python 3.14 if it remains unused.
7. Activate the new configuration so Home Manager creates the declared machine with its generated configuration bind mount.
8. Start a fresh login shell so executable lookup and Home Manager session variables cannot retain the Homebrew environment.
9. Start the machine manually and run the live validation checks below.

The old image cache is intentionally not exported. Images are re-downloaded as needed.

## Security and failure behavior

- The machine remains rootless.
- No launchd watchdog keeps it running without an explicit user start.
- Registry credentials and mutable Docker configuration are not changed.
- Existing safe-read, hard-deny, and prompt-based agent rules remain unchanged.
- Container execution, image publication, host mounts, and lifecycle mutations remain approval-gated for coding agents.
- If containers or named volumes appear before cutover, deletion is blocked rather than silently discarding them.
- If activation fails after VM deletion, the VM may be recreated manually or the previous configuration restored. At the approved baseline, no unique container or volume data requires recovery.
- If the machine is stopped, Podman, Docker, and Compose clients fail with normal connection errors.

## Validation

Before cutover:

1. Run targeted formatting and Statix checks on every changed Nix file.
2. Evaluate Darwin host `t0` and verify:
   - `home-manager.dev.podman.enable` and `services.podman.enable` are true;
   - `services.podman.useDefaultMachine` is false;
   - exactly `podman-machine-default` is declared;
   - CPU, memory, disk, mounts, rootful mode, and `autoStart` match the host specification;
   - no Podman launchd agent is generated;
   - the Home Manager package set contains Podman, Docker CLI, and `docker-compose`, but not `podman-compose`;
   - Homebrew brews exclude `podman`, `podman-compose`, `docker`, and `docker-compose`;
   - container-agent permissions remain enabled;
   - the generated session-variable script contains the runtime-expanded `$TMPDIR` socket expression.
3. Build the `t0` Home Manager activation package without activating it.
4. Evaluate `pvg1-nixos` and `jetson-nixos` to prove existing NixOS and disabled-host behavior is unchanged.
5. Run representative container agent-policy checks to prove the ownership migration does not broaden authorization.
6. Run `git diff --check` and inspect the complete diff for unrelated changes.

After the separately confirmed cutover:

1. Inspect the recreated machine and verify 4 CPUs, 8192 MiB memory, 100 GiB disk, rootless mode, and expected mounts.
2. Confirm no Podman launchd watchdog exists.
3. Verify `podman`, `docker`, and `docker-compose` resolve from the Nix store or an intended Nix profile, and that the fresh shell has the expected `$TMPDIR`-based `DOCKER_HOST`.
4. Verify `/var/run/docker.sock` is neither a file nor a symlink and the user's `podman-mac-helper` launchd plist is absent.
5. Start the machine manually and verify `podman info` connects.
6. Use connection-bearing commands such as `docker ps` and `docker-compose ls` to verify both clients reach Podman through `DOCKER_HOST`.
7. Verify `podman compose` selects `docker-compose` and connects with `podman compose ls`.
8. Verify Homebrew no longer owns the four container formulas and that no Homebrew Python remains solely because of them.

## Rollback

Before cutover, rollback is a source revert because no live state has changed.

After cutover, restore and activate the previous configuration to reinstall the Homebrew clients, then recreate and start a Homebrew-managed machine manually if needed. Reinstall `podman-mac-helper`, start a fresh login shell, and verify the restored `/var/run/docker.sock` with connection-bearing Docker and Compose commands. The deleted image cache is not restored. If unique container or volume state is discovered before cutover, this rollback model is invalid and migration must stop until that state has a preservation plan.
