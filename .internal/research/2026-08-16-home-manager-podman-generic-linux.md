# Research: Home Manager Podman on generic Linux

> **Date:** 2026-08-16
> **Bead:** nix-configs-k62
> **Status:** Complete

## Summary

Home Manager's upstream `services.podman` module supports native Linux and is appropriate for non-NixOS hosts, where standalone Home Manager is the available integration model. The repository wrapper can therefore support generic Linux, but it must use native Linux semantics rather than the Darwin machine and `$TMPDIR` socket path, and it cannot replace host-level rootless prerequisites.

## Key Findings

### Upstream Home Manager supports native Linux Podman

> **Confidence:** high — the official option reference, the repository's locked Home Manager source, and a clean generic-Linux evaluation agree.

The pinned module installs its selected Podman package and writes `containers.conf`, `policy.json`, `registries.conf`, and `storage.conf` under the user's XDG configuration on Linux [S1]. Its Linux modules also support declarative Quadlet builds, containers, images, networks, and volumes [S2].

A clean evaluation using the repository's exact pins and `x86_64-linux` produced Podman 5.8.4, the four container configuration files, and `podman-auto-update` user service and timer definitions. The same evaluation showed `services.podman.autoUpdate.enable = true`; the official option reference documents the default calendar as Sunday at 00:00 [S2]. The pinned service runs `podman image prune -f` after automatic updates, so this behavior should not be inherited silently by a development-tool wrapper [S7].

### Home Manager does not own all generic-Linux prerequisites

> **Confidence:** high for the normal rootless setup, with a documented exception for Podman's single-UID HPC mode.

Normal rootless Podman uses subordinate UID and GID ranges from `/etc/subuid` and `/etc/subgid` [S3]. The pinned Home Manager source also notes that `newuidmap` must be setuid and that non-NixOS distributions must provide it through a host package such as Ubuntu's `uidmap` [S4]. These `/etc` entries and privileged helper installation remain host responsibilities; a user Home Manager activation should not attempt to own them.

Podman documents an HPC mode that can operate with a single UID, so subordinate ranges are not an unconditional requirement for every possible rootless deployment [S3]. It is not the default target for this repository.

### Docker compatibility uses the native rootless socket

> **Confidence:** high — official Podman service documentation and the pinned Home Manager evaluation agree.

On native rootless Linux, the Docker-compatible API endpoint is `unix://$XDG_RUNTIME_DIR/podman/podman.sock`. Podman's standard user socket is activated with `systemctl --user start podman.socket`, and it can be enabled with user lingering when availability across logouts or reboots is required [S5].

The clean Home Manager evaluation declared only `podman-auto-update` in `systemd.user.services` and `systemd.user.timers`; it did not declare or enable `podman.socket`. Therefore a repository wrapper that installs `docker-client` and `docker-compose` must either own an explicit user socket/service or make socket activation a documented host prerequisite. Setting `DOCKER_HOST` alone is insufficient.

### Socket activation is the appropriate Docker-compatibility integration

> **Confidence:** high — the current Podman and Docker documentation explicitly describe this client/server boundary, and an independent citation check confirmed the Podman guidance.

Native Podman commands should remain daemonless. When real Docker API clients are an explicit requirement, Podman documents systemd user socket activation as the standard integration: clients connect to `%t/podman/podman.sock`, systemd starts `podman system service` on demand, and the API process exits again after its inactivity timeout [S5]. Docker documents `DOCKER_HOST` as the daemon socket selected by the CLI, and Docker Compose inherits it [S8].

For this repository, enabling the rootless user socket is therefore appropriate only because the development wrapper deliberately includes the real Docker CLI and Compose. The socket must remain a user-owned Unix socket; it must not be exposed over TCP, because the Podman API grants full Podman access and arbitrary code execution as that user [S5]. User lingering is unnecessary unless a host explicitly needs the API to remain available across logouts.

### NixOS should retain system ownership

> **Confidence:** high — current repository modules already provide the complete NixOS integration.

The NixOS paths enable `virtualisation.podman`, `dockerCompat`, and `dockerSocket` at the system layer, then bridge the resulting capability into Home Manager agent permissions. Enabling the repository's Home Manager Podman wrapper there would duplicate package and configuration ownership without solving a missing platform function.

## Comparisons

| Host type | Podman owner | Machine model | Docker socket owner |
|-----------|--------------|---------------|---------------------|
| Darwin | Home Manager `services.podman` | Declared Podman VM | Repository wrapper targets the forwarded `$TMPDIR` socket |
| NixOS | NixOS `virtualisation.podman` | Native Linux, no VM | NixOS `dockerSocket` and `dockerCompat` |
| Non-NixOS Linux | Home Manager `services.podman`, plus distro prerequisites | Native Linux, no VM | Explicit Home Manager user socket or documented distro/user setup |

## Codebase Context

- `modules/home-manager/dev/podman.nix` currently rejects every non-Darwin host, requires `podman-machine-default`, and sets a Darwin-only `$TMPDIR` socket.
- `modules/nixos/dev/virtualisation/default.nix` and `modules/nixos/system/virtualisation.nix` already own NixOS Podman and Docker compatibility.
- `modules/nixos/home.nix` bridges final NixOS Podman enablement into coding-agent permissions.
- Standalone Linux hosts such as `mbx`, `metax`, and `pvg1` set `targets.genericLinux.enable = true`, which provides a repository-local discriminator for the generic-Linux branch.
- Home Manager officially identifies standalone Home Manager as the integration available on platforms other than NixOS and Darwin, while warning that support can vary across Linux distributions [S6].

## Recommendations

1. Keep one `home-manager.dev.podman.enable` interface, but branch its implementation by platform.
2. Preserve the current Darwin machine inventory and `$TMPDIR` socket behavior unchanged.
3. On `pkgs.stdenv.hostPlatform.isLinux && config.targets.genericLinux.enable`, enable upstream `services.podman`, install `docker-client` and `docker-compose`, enable container-agent permissions, and use `unix://$XDG_RUNTIME_DIR/podman/podman.sock`.
4. Set `services.podman.autoUpdate.enable = lib.mkDefault false` in the generic-Linux development wrapper. Hosts that deliberately manage auto-updated Quadlets can override it.
5. Because the wrapper includes the real Docker CLI and Compose, have it own the rootless `podman.socket` user unit and expose that Unix socket through `DOCKER_HOST`.
6. Require the generic Linux host to supply working rootless prerequisites, especially the normal `/etc/subuid` and `/etc/subgid` ranges and setuid `newuidmap`/`newgidmap` helpers.
7. Leave NixOS on `virtualisation.podman`; do not enable the Home Manager wrapper in NixOS configurations.

## Recommended Beads

- `bd create "Design generic-Linux support for home-manager.dev.podman" -t feature -p 2 --notes "Severity: Important\nConfidence: Confirmed\nEvidence: .internal/research/2026-08-16-home-manager-podman-generic-linux.md"` — decide socket ownership and extend the wrapper without changing NixOS ownership.

## Open Questions

- Which existing standalone Linux host should be the first evaluation and activation target?

## Refuted / Discarded Claims

- **"The existing Darwin wrapper can simply drop its platform assertion."** Refuted: its machine requirement and `$TMPDIR` socket are invalid for native Linux.
- **"Enabling upstream `services.podman` automatically enables the Docker API socket."** Refuted by the pinned generic-Linux evaluation; only the auto-update service and timer were declared.
- **"Every rootless Podman configuration requires subordinate UID/GID ranges."** Too broad: normal rootless mode does, but Podman documents a constrained single-UID HPC mode.

## Verification Notes

Independent web fetches of the pinned GitHub blob URLs cache-missed. Those claims were checked against the exact locked Home Manager source at revision `367f7ef80856d18438953d54dda235d42a46ba31` in the Nix store and against a clean generic-Linux evaluation; the official Home Manager option reference independently confirmed the Linux options and auto-update defaults. The Podman rootless and socket claims were narrowed after citation review so they do not overstate the official documentation.

## Sources

- [Pinned Home Manager Podman module](https://github.com/nix-community/home-manager/blob/367f7ef80856d18438953d54dda235d42a46ba31/modules/services/podman/default.nix) — Primary/Official — 2026-08-16 — package installation and Linux XDG configuration. [S1]
- [Home Manager Podman option reference](https://nix-community.github.io/home-manager/options/home-manager/services/podman.html) — Primary/Official — accessed 2026-08-16 — Linux Quadlet options and auto-update defaults. [S2]
- [Podman rootless documentation](https://docs.podman.io/en/stable/markdown/podman.1.html) — Primary/Official — accessed 2026-08-16 — subordinate IDs, rootless configuration, and HPC exception. [S3]
- [Pinned Home Manager Linux Podman helper paths](https://github.com/nix-community/home-manager/blob/367f7ef80856d18438953d54dda235d42a46ba31/modules/services/podman/linux/podman-lib.nix) — Primary/Official — 2026-08-16 — setuid `newuidmap` and non-NixOS `uidmap` requirement. [S4]
- [Podman system service documentation](https://docs.podman.io/en/latest/markdown/podman-system-service.1.html) — Primary/Official — accessed 2026-08-16 — rootless API socket path and systemd user socket activation. [S5]
- [Home Manager README](https://github.com/nix-community/home-manager) — Primary/Official — accessed 2026-08-16 — standalone generic-Linux integration and support warning. [S6]
- [Pinned Home Manager Linux Podman services](https://github.com/nix-community/home-manager/blob/367f7ef80856d18438953d54dda235d42a46ba31/modules/services/podman/linux/services.nix) — Primary/Official — 2026-08-16 — automatic-update service, timer, and post-update image prune. [S7]
- [Docker CLI reference](https://docs.docker.com/reference/cli/docker/) — Primary/Official — accessed 2026-08-16 — `DOCKER_HOST` selects the daemon socket used by the Docker client. [S8]
