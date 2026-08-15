# Podman installation and agent permissions design

## Context

The current local change adds Podman command permissions to the shared coding-agent configuration. It introduces a Home Manager virtualization option only as a permission signal, while Podman installation remains controlled elsewhere. The proposed command allowlist also grants broad prefixes such as `podman run`, `podman system`, and `podman volume`, which automatically approve destructive operations and host-path mounts.

The configuration needs one platform-owned installation decision, an explicit signal to Home Manager that container tooling is available, and permission rules that distinguish safe reads from prohibited bulk deletion while prompting for all other operations.

## Goals

- Make Podman installation conditional on an explicit platform option.
- Provide Podman-backed Docker command compatibility without Docker Desktop.
- Emit Podman and Docker agent permissions only when the tools are installed.
- Automatically allow a narrow set of read-only inspection commands.
- Reject catastrophic bulk-deletion commands.
- Leave all other container commands subject to the agents' normal approval prompt.
- Apply the same policy to Codex, Claude Code, OpenCode, and Antigravity CLI through the existing shared permission renderer.

## Non-goals

- Install or manage Docker Desktop or a Docker daemon.
- Automatically create or start a Podman machine on macOS.
- Manage registry authentication or `~/.docker/config.json`.
- Automatically approve container builds, runs, host mounts, publication, or lifecycle mutations.
- Refactor the existing NixOS developer and system virtualization option hierarchy.

## Ownership and option flow

Installation remains owned by the operating-system module because Home Manager cannot install or configure system-level virtualization reliably.

### NixOS

`virtualisation.podman.enable` remains the source of truth. The existing `nixos.dev.virtualisation.enable` and `nixos.system.virtualisation.enable` options may continue enabling it for their respective host profiles. `virtualisation.podman.dockerCompat` and `virtualisation.podman.dockerSocket.enable` remain enabled with Podman.

The NixOS-to-Home-Manager bridge derives the permission capability from the evaluated value of `virtualisation.podman.enable`. This replaces duplicate permission wiring in the two higher-level virtualization modules.

### nix-darwin

Add `nix-darwin.homebrew.podman.enable` beneath the existing Homebrew module. It defaults to the parent `nix-darwin.homebrew.enable` value so current installation behavior is preserved, while allowing Podman to be disabled independently.

When enabled, the Homebrew module installs:

- `podman`
- `podman-compose`
- `docker`
- `docker-compose`

Docker Desktop is not installed. The Darwin Home Manager bridge sets `DOCKER_HOST` to `unix://${config.home.homeDirectory}/.local/share/containers/podman/machine/podman.sock` so Docker-compatible clients use the Podman engine. A missing or stopped Podman machine produces the normal client connection error; activation does not create or start one.

The standalone `docker-compose` command is supported. The configuration does not take ownership of mutable `~/.docker/config.json` solely to make the same executable discoverable as the `docker compose` plugin.

### Home Manager capability

Add `home-manager.dev.coding-agents.permissions.containers.enable`, defaulting to `false`. This option represents only the availability of Podman-backed container commands to coding agents; it does not install virtualization software.

The NixOS and nix-darwin system modules set this capability when their Podman installation option is enabled. The shared permissions module uses it to include or omit all container command rules.

## Permission policy

Keep separate `containerAllowedCommands` and `containerDeniedCommands` lists. Both lists contain equivalent Podman and Docker forms where the tools expose equivalent commands.

Automatically allowed commands are limited to these read-only prefixes:

- For both `podman` and `docker`: `ps`, `images`, `inspect`, `logs`, `info`, `version`, `port`, `top`, `stats`, `container inspect`, `container ls`, `image inspect`, `image ls`, `network inspect`, `network ls`, `volume inspect`, `volume ls`, and `system df`.
- For Podman only: `pod inspect`, `pod ps`, `machine inspect`, and `machine list`.
- Standalone Compose version reporting: `podman-compose --version` and `docker-compose version`.

Explicitly rejected commands are limited to these catastrophic or bulk-deletion prefixes:

- For Podman: `system reset`, `system prune`, `container prune`, `image prune`, `network prune`, `pod prune`, `volume prune`, `machine reset`, and `machine rm`.
- For Docker: `system prune`, `container prune`, `image prune`, `network prune`, `volume prune`, `builder prune`, and `buildx prune`.

Commands in neither list use the existing prompt behavior. This includes `build`, `run`, `exec`, `pull`, `push`, create/start/stop/remove, Compose mutations, and network or volume mutations. In particular, no broad `podman run`, `docker run`, `podman system`, `docker system`, `podman volume`, or `docker volume` prefix is automatically allowed.

The rejected prefixes are hard denials for configured agents. A human can still run them manually outside an agent session.

## Security and failure behavior

- Container execution cannot bypass approval through an automatically allowed `run` prefix or privileged host mount.
- Registry publication remains approval-gated.
- Bulk cleanup cannot be approved accidentally through a broad parent prefix.
- Enabling Homebrew alone does not implicitly enable container permissions when the nested Podman option is disabled.
- A platform that does not install Podman does not emit Podman or Docker permission rules.
- Existing non-container permission behavior is unchanged.
- The unrelated local `corepack` permission change is excluded from this work.

## Validation

1. Run targeted formatting and Statix checks on every changed Nix file.
2. Evaluate Darwin host `t0` and verify the Podman option, Homebrew packages, `DOCKER_HOST`, and Home Manager container-permission capability are enabled.
3. Evaluate NixOS host `pvg1-nixos` and verify Podman, Docker compatibility, and the Home Manager capability are enabled.
4. Evaluate `jetson-nixos` and verify the capability and generated container permission rules remain disabled.
5. Use `codex execpolicy check` against the generated rules to verify representative Podman and Docker commands in each state:
   - inspection is allowed;
   - catastrophic cleanup is forbidden;
   - build or run has no matching rule and therefore prompts.
6. Evaluate the other coding-agent settings to confirm their generated allow and deny patterns contain the same policy categories.
7. Run `git diff --check` and inspect the final diff for unrelated changes.

## Rollback

Disable the platform Podman option to remove the installed tools and derived agent permissions together. Reverting the permission-list changes restores the previous agent policy without changing unrelated development tooling.
