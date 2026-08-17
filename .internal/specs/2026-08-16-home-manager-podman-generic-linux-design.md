# Home Manager Podman support for generic Linux

## Context

`home-manager.dev.podman` currently owns the Podman development environment on Darwin. It enables Home Manager's upstream Podman service, requires a host-declared `podman-machine-default`, installs the Docker CLI and Compose, points Docker clients at the machine's forwarded API socket, and enables coding-agent container permissions.

Standalone non-NixOS Linux hosts also use Home Manager, but they run Podman natively rather than through a virtual machine. The existing Darwin assertions and `$TMPDIR` socket are therefore invalid on those hosts. NixOS already has complete system-level ownership through `virtualisation.podman` and must not adopt the Home Manager runtime wrapper.

## Goals

- Allow `home-manager.dev.podman` on standalone Linux hosts that enable `targets.genericLinux` and run a systemd user manager.
- Preserve the current Darwin machine behavior and host-configurable machine specification.
- Provide the real Docker CLI and Docker Compose against rootless Podman on generic Linux.
- Use Podman's standard socket-activated user API service rather than a permanently running service.
- Keep NixOS Podman ownership at the system layer.

## Non-goals

- Enable the wrapper on NixOS.
- Manage `/etc/subuid`, `/etc/subgid`, `newuidmap`, or `newgidmap` from Home Manager.
- Configure rootful Podman on generic Linux.
- Expose the Podman API over TCP.
- Enable user lingering.
- Support non-systemd Linux distributions.
- Automatically enable Podman on an existing standalone Linux host.
- Activate a Home Manager generation or mutate a running Podman installation.

## Public interface and platform ownership

Keep `home-manager.dev.podman.enable` as the only repository-specific public option. Hosts may override upstream `services.podman` options directly when they need behavior beyond the wrapper defaults.

The implementation branches internally:

- On Darwin, preserve the existing declarative machine, packages, forwarded socket, and coding-agent permission behavior. The Darwin host owns `services.podman.useDefaultMachine = false` beside its machine resources so Home Manager's default machine does not overwrite them.
- On Linux, require `targets.genericLinux.enable` and use native rootless Podman semantics.
- On NixOS, leave the wrapper disabled. `virtualisation.podman` remains the runtime owner, and the existing NixOS bridge continues deriving coding-agent permissions from its evaluated enablement.

The Darwin assertion for `services.podman.machines.podman-machine-default` applies only to Darwin. The wrapper rejects unsupported platforms and Linux configurations that do not enable `targets.genericLinux`.

## Generic-Linux runtime behavior

When enabled on generic Linux, the wrapper:

- enables upstream `services.podman`;
- defaults `services.podman.autoUpdate.enable` to `false`, while allowing an explicit host override;
- installs `docker-client` and `docker-compose` alongside the Podman package selected by `services.podman`;
- enables coding-agent container permissions;
- sets `DOCKER_HOST` to `unix://$XDG_RUNTIME_DIR/podman/podman.sock`;
- exposes the selected Podman package's standard rootless `podman.socket` and `podman.service` through Home Manager's `systemd.user.packages`; and
- enables the packaged socket under `sockets.target` without directly enabling the service.

The socket listens at `%t/podman/podman.sock`. A Docker client connection causes systemd to start `podman system service` on demand; the API process exits after its inactivity timeout and starts again for a later connection. Native `podman` commands remain daemonless.

Home Manager must link the packaged units instead of recreating them. The socket enablement link must target the `podman.socket` supplied by `services.podman.package`; it must not introduce a different socket path or persistent-service model.

## Host prerequisites and failure behavior

The Linux distribution remains responsible for a working systemd user manager and for the privileged pieces of a normal rootless Podman installation, including subordinate UID/GID allocation and setuid mapping helpers. Home Manager must not attempt to modify `/etc` or install setuid helpers during user activation.

The wrapper does not add activation-time assertions for those external prerequisites because their correct state cannot be determined reliably from a pure Home Manager evaluation. A missing prerequisite or failed API service remains visible through the normal Podman or Docker error and through `journalctl --user -u podman.service`.

The API is exposed only through the user-owned Unix socket. The wrapper does not configure a TCP listener or lingering. This keeps access within the standard rootless permission boundary; any process that can access the socket can exercise full Podman functionality as that user.

## Validation

1. Evaluate the Darwin `t0` configuration and confirm its machine inventory, Podman package, Docker packages, coding-agent permission capability, and `$TMPDIR`-based `DOCKER_HOST` are unchanged.
2. Evaluate a clean standalone `x86_64-linux` Home Manager configuration with `targets.genericLinux.enable` and `home-manager.dev.podman.enable` set. Confirm:
   - Podman, Docker CLI, and Docker Compose are installed;
   - automatic updates default to disabled;
   - the selected Podman package supplies the user units through `systemd.user.packages`;
   - the packaged `podman.socket` is enabled under `sockets.target`;
   - `podman.service` is socket-activated and not directly enabled; and
   - `DOCKER_HOST` is `unix://$XDG_RUNTIME_DIR/podman/podman.sock`.
3. Evaluate a NixOS configuration and confirm `virtualisation.podman` and its Home Manager permission bridge remain unchanged.
4. Evaluate an unsupported Linux configuration without `targets.genericLinux.enable` and confirm the wrapper rejects it with a specific assertion.
5. Run targeted formatting and Statix checks for changed Nix files, `git diff --check`, and the relevant flake checks.
6. Inspect the final diff for unrelated changes. Do not activate a host as part of validation without separate authorization.

## Rollback

Disabling `home-manager.dev.podman.enable` on a generic-Linux host removes the Home Manager-managed Podman environment, Docker clients, user socket/service declarations, `DOCKER_HOST`, and derived coding-agent permission capability from the next generation. Host-owned subordinate-ID configuration and privileged helpers remain untouched.

Reverting the generic-Linux branch leaves the existing Darwin and NixOS ownership paths unchanged.
