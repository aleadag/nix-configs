# Research: Home Manager Podman ownership on Darwin

> **Date:** 2026-08-16
> **Bead:** nix-configs-3rq
> **Status:** Complete

## Summary

The Python version pressure comes from Homebrew `podman-compose`, not from Homebrew `podman`: the former directly depends on `python@3.14`, while the latter has no macOS runtime formula dependencies. Moving the entire stack to Home Manager's `services.podman` is therefore not required to solve the Python problem, and is not a drop-in package-source change because the service also creates, starts, and exclusively owns Podman machines on Darwin.

## Key Findings

### Homebrew `podman-compose` owns the visible Python dependency

> **Confidence:** high — official Homebrew formula metadata independently verified.

As of 2026-08-16, Homebrew `podman-compose` 1.6.0 directly depends on `python@3.14`, `podman`, and `libyaml`; Homebrew `podman` 6.1.0 has no macOS runtime formula dependencies and uses the system Python only as a build input [S1][S2]. This makes `podman-compose`, rather than Podman itself, the source of the extra Homebrew-managed Python [S1][S2].

This is inherent to the implementation: upstream `podman-compose` is a Python application requiring Python 3.9 or newer [S3]. The pinned Nixpkgs `podman-compose` also embeds Python, but Nix keeps that interpreter and its libraries in the application's isolated store closure rather than exposing another shared Homebrew Python version [S4][S5].

### `docker-compose` can provide Compose without Python

> **Confidence:** high — official Podman documentation and both package definitions agree.

Podman's `podman compose` command delegates to an external provider and supports either `docker-compose` or `podman-compose`; when both are installed, `docker-compose` takes precedence [S6]. The current configuration already installs `docker-compose`, whose current Homebrew and pinned Nixpkgs packages are Go applications without a Python runtime dependency [S7]. Therefore removing only `podman-compose` preserves a supported Compose provider while eliminating this Homebrew Python requirement.

### `services.podman` changes VM ownership, not just package ownership

> **Confidence:** high — verified against the repository's exact locked Home Manager source; two independent citation checks supported the deletion behavior.

The option name is `services.podman`, not `home-manager.service.podman`. On Darwin, `services.podman.enable = true` defaults `useDefaultMachine` to true, declares `podman-machine-default`, marks it for automatic start, and creates a per-user launchd watchdog [S8].

More importantly, activation enumerates all existing Podman machines and stops then force-removes every machine whose name is absent from the declared managed set [S8]. Existing machines must be identified and declared before the first activation. Changes to an already-created machine's CPU, memory, disk, volumes, or provider are not reconciled because activation initializes a declared machine only when its name does not already exist [S8].

This behavior conflicts with the current approved design, whose non-goals say not to create or start a Podman machine and whose ownership section keeps Darwin installation under Homebrew.

### Home Manager does not reproduce the current compatibility clients or socket

> **Confidence:** high for package and socket mechanics — locked source, local evaluation, and official Podman documentation agree.

The Home Manager module's common configuration adds its selected `services.podman.package` to `home.packages`; it does not declare the current Docker CLI, `docker-compose`, or `podman-compose` packages [S9]. A local evaluation at the repository's pins produced only `podman-5.8.4` for the module-managed Podman package, so those clients need separate Nix package declarations.

The pinned Nixpkgs Darwin build intentionally does not install `podman-mac-helper`. Podman documents that without the helper's global Docker socket, Docker API clients must use `DOCKER_HOST` pointing to the machine's forwarded Unix socket [S10][S11]. The current repository value, `unix:///var/run/docker.sock`, must therefore be replaced with a value derived from the actual machine connection rather than carried over unchanged.

### The current pins introduce a Podman version change

> **Confidence:** medium — Homebrew metadata and local pinned evaluation agree; the independent verifier could not re-fetch the pinned Nixpkgs source.

Homebrew currently supplies Podman 6.1.0 [S2]. The repository's locked Nixpkgs revision and local evaluation supply Podman 5.8.4 [S12]. A move to Home Manager's default package is presently a 6.1.0 to 5.8.4 downgrade and may also change VM-provider defaults when the Nix package is later updated; this needs an explicit compatibility decision rather than being treated as a packaging-only migration.

## Comparisons

| Approach | Solves visible Homebrew Python | Changes Podman CLI owner | Changes VM lifecycle owner | Main cost |
|----------|--------------------------------|--------------------------|----------------------------|-----------|
| Remove Homebrew `podman-compose` only | Yes | No | No | Smallest change; retain Homebrew Podman |
| Install Nix Podman and Compose packages without `services.podman` | Yes | Yes | No | Must configure packages and dynamic Docker socket explicitly |
| Enable `services.podman` | Yes, if `podman-compose` is omitted or isolated in Nix | Yes | Yes | Activation owns machines, launchd, config files, and unmanaged-machine removal |

## Codebase Context

- `modules/nix-darwin/homebrew.nix` currently makes `nix-darwin.homebrew.podman.enable` default to the parent Homebrew flag, installs `docker`, `docker-compose`, `podman`, and `podman-compose`, enables agent permissions, and sets `DOCKER_HOST=unix:///var/run/docker.sock`.
- `modules/home-manager/darwin/homebrew.nix` only integrates the Homebrew prefix into the Home Manager environment; it does not own Podman lifecycle.
- `.internal/specs/2026-08-16-podman-installation-agent-permissions-design.md` explicitly assigns Darwin installation to Homebrew and excludes automatic machine creation/start.
- `.internal/plans/2026-08-16-podman-installation-agent-permissions.md` implements that approved ownership boundary, so a full service migration requires revising both the design and plan before code.
- The repository pins Home Manager at `367f7ef80856d18438953d54dda235d42a46ba31` and Nixpkgs at `f13ff45afd1bb73e640eaa08a7066dbed07e3238`.

## Recommendations

1. For the stated Python-maintenance problem, remove only Homebrew `podman-compose` first and retain `docker-compose` as Podman's external Compose provider. This is the smallest change and preserves the current manual VM lifecycle.
2. If the broader objective is to remove Podman from Homebrew, move the CLI packages to Nix separately from VM lifecycle ownership. Do not enable `services.podman` merely as a package installer.
3. Adopt `services.podman` only if declarative creation, auto-start, and exclusive ownership of all Podman machines are desired. Before the first activation, inventory and preserve every existing machine, explicitly declare intended machines, and validate their data.
4. For either Nix-owned route, choose explicit Docker/Compose packages, derive the correct forwarded socket for `DOCKER_HOST`, and resolve or accept the current Podman version downgrade.
5. Revise the existing Podman design and implementation plan before changing code because full Home Manager service ownership reverses an approved architecture decision.

## Recommended Beads

None until the user chooses package-only migration or full machine ownership. The existing design must be revised before implementation rather than creating implementation tasks against contradictory requirements.

## Open Questions

- Is the desired outcome only removal of Homebrew's Python, or complete removal of Podman-related Homebrew formulas?
- Should Home Manager own and auto-start the existing Podman machine, including removing any undeclared machines?
- Must the existing Docker CLI and standalone Compose commands remain available?
- Is Podman 5.8.4 acceptable, or must the Nix package be updated or overridden to match 6.1.0 first?

## Refuted / Discarded Claims

- **“Homebrew Podman itself installed Python.”** Refuted: `podman-compose` is the direct Python-dependent formula; `podman` has no macOS runtime formula dependencies.
- **“`services.podman` is a drop-in replacement for the four Homebrew formulas.”** Refuted: it adds Podman and owns machine lifecycle, but does not reproduce the current Docker and Compose package set.
- **“Moving `podman-compose` to Nix removes Python.”** Refuted: it isolates Python in the Nix closure; omitting `podman-compose` and using `docker-compose` removes that runtime.
- **“The current `/var/run/docker.sock` value can be retained.”** Refuted for the pinned Nix Podman build: `podman-mac-helper` is not installed, so Docker clients must target the forwarded machine socket.

## Sources

- [Homebrew `podman-compose` formula API](https://formulae.brew.sh/api/formula/podman-compose.json) — Primary/Official — generated 2026-08-12 — version and runtime dependencies. [S1]
- [Homebrew `podman` formula API](https://formulae.brew.sh/api/formula/podman.json) — Primary/Official — generated 2026-08-14 — version and absence of macOS runtime dependencies. [S2]
- [`podman-compose` 1.6.0 project metadata](https://github.com/containers/podman-compose/blob/v1.6.0/pyproject.toml) — Primary/Official — accessed 2026-08-16 — Python requirement and dependencies. [S3]
- [Pinned Nixpkgs `podman-compose`](https://github.com/NixOS/nixpkgs/blob/f13ff45afd1bb73e640eaa08a7066dbed07e3238/pkgs/by-name/po/podman-compose/package.nix) — Primary/Official — accessed 2026-08-16 — isolated Python application packaging. [S4]
- [Nixpkgs Python manual](https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md) — Primary/Official — accessed 2026-08-16 — application dependency isolation. [S5]
- [Podman Compose documentation](https://docs.podman.io/en/v5.8.3/markdown/podman-compose.1.html) — Primary/Official — accessed 2026-08-16 — external Compose provider behavior. [S6]
- [Homebrew `docker-compose` formula API](https://formulae.brew.sh/api/formula/docker-compose.json) — Primary/Official — generated 2026-08-14 — Go package with no runtime formula dependencies. [S7]
- [Pinned Home Manager Darwin Podman module](https://github.com/nix-community/home-manager/blob/367f7ef80856d18438953d54dda235d42a46ba31/modules/services/podman/darwin.nix) — Primary/Official — 2026-08-09 pin — machine creation, launchd, and unmanaged-machine removal. [S8]
- [Pinned Home Manager Podman module](https://github.com/nix-community/home-manager/blob/367f7ef80856d18438953d54dda235d42a46ba31/modules/services/podman/default.nix) — Primary/Official — 2026-08-09 pin — package and container configuration ownership. [S9]
- [Pinned Nixpkgs Podman package](https://github.com/NixOS/nixpkgs/blob/f13ff45afd1bb73e640eaa08a7066dbed07e3238/pkgs/by-name/po/podman/package.nix) — Primary/Official — 2026-08-07 pin — Podman version and omitted mac helper. [S10][S12]
- [Podman 5.8.4 machine-start documentation](https://github.com/containers/podman/blob/v5.8.4/docs/source/markdown/podman-machine-start.1.md) — Primary/Official — accessed 2026-08-16 — forwarded API socket and `DOCKER_HOST`. [S11]
