# Typed Niri Configuration Migration

## Goal

Replace the hand-written KDL document in the Home Manager Niri module with
`niri-flake`'s typed `programs.niri.settings` interface, use its unstable Niri
and Xwayland Satellite packages for managed sessions, and keep UWSM responsible
for session startup.

## Scope

The migration covers the Niri package source, Home Manager configuration
generation, and the existing Niri settings. It does not replace the repository's
NixOS session, portal, keyring, or UWSM integration and does not change the
cross-platform keybinding policy.

## Dependency Integration

- Add `github:sodiboo/niri-flake` as the `niri` flake input.
- Set `niri.inputs.nixpkgs.follows = "nixpkgs"` and
  `niri.inputs.nixpkgs-stable.follows = "nixpkgs-stable"` to avoid redundant
  package-set pins.
- Apply `niri.overlays.niri` so `pkgs.niri-unstable` and
  `pkgs.xwayland-satellite-unstable` are available in the repository package
  set.
- Continue using nixpkgs's `pkgs.niri` as the NixOS-installed launcher and as
  the validation fallback when Home Manager is configured with `package = null`.
- Do not enable `niri.nixosModules.niri` or its binary-cache option; use
  `niri.homeModules.niri` for managed Home Manager sessions.

## Module Architecture

The existing NixOS module remains responsible for:

- enabling UWSM and registering the Niri UWSM compositor entry;
- installing the system Niri launcher and exposing its fallback systemd units;
- configuring GNOME portals, GNOME Keyring, and the repository's portal
  selection policy;
- passing the repository's Niri enablement into Home Manager.

The Home Manager Niri module imports `niri.homeModules.niri` and
`niri.homeModules.stylix`. The explicit Stylix import is required because this
repository imports Stylix inside Home Manager and disables its NixOS-to-Home
Manager auto-import. The Niri Stylix target is disabled on non-Linux systems so
the shared Home Manager module does not evaluate niri-flake's Linux package on
Darwin. The module remains responsible for:

- the repository-specific enable and nullable package options;
- the Niri power-menu helper;
- selecting the managed Niri package and exposing its systemd user units;
- enabling integrated Xwayland Satellite with the matching unstable package;
- translating repository settings and package paths into
  `programs.niri.settings`.

The generated configuration data flows as follows:

1. Repository options, package paths, and the niri-flake Stylix adapter populate
   `programs.niri.settings`.
2. The config module imported by `niri.homeModules.niri` serializes those typed
   values to KDL.
3. The module validates the generated KDL with the selected Niri package,
   defaulting to `pkgs.niri-unstable` and falling back to `pkgs.niri` when the
   wrapper package is null.
4. Home Manager installs the validated file as `$XDG_CONFIG_HOME/niri/config.kdl`.

## Typed Settings Conversion

Translate every effective setting from the current KDL document, omitting
literal values that are identical to the pinned Niri defaults:

- keyboard layout, variant, XKB options, numlock, pointer, and touchpad input;
- workspace behavior and layout dimensions;
- focus-ring, border, shadow, and geometry settings;
- startup commands, screenshot path, hotkey overlay, and environment variables;
- active window and layer rules;
- every active keybinding, including command arguments and keybinding metadata.

Remove sample comments, commented examples, empty nodes, and disabled rules that
have no runtime effect. Import `niri.homeModules.stylix` so the cursor theme,
cursor size, and active/inactive border colors follow Stylix automatically. The
repository still controls focus-ring, border, and shadow enablement and geometry,
while their redundant literal colors fall back to the pinned Niri defaults. The
wallpaper command remains Stylix-derived.

The workspace bindings must continue to match `docs/keybinding-conventions.md`:

- `Mod+q..p` focuses workspaces 1 through 10;
- `Mod+Shift+q..p` moves columns to workspaces 1 through 10;
- Page Up and Page Down retain relative focus and move behavior.

## Compatibility Decisions

- Managed Home Manager sessions use `pkgs.niri-unstable` because integrated
  Xwayland Satellite and the current typed actions require the matching unstable
  schema and package. Build-time validation remains the compatibility gate.
- UWSM remains the configured session-launch strategy and continues launching
  `/run/current-system/sw/bin/niri-session`. For managed sessions, the Home
  Manager-provided `niri.service` starts the selected unstable package.
- Integrated Xwayland Satellite is enabled with
  `pkgs.xwayland-satellite-unstable`; the former repository-specific Xwayland
  option is removed.
- The existing nullable package option is retained for compatibility. When it is
  null, Home Manager still generates the typed configuration but omits Niri and
  its systemd user units while validating against `pkgs.niri`.
- Screenshots are saved under `~/Pictures/Screenshots`.

## Validation

Use `pvg1-nixos` as the representative Niri-enabled host.

1. Before the conversion, realize and retain the current generated Niri config
   as a behavioral reference.
2. After the conversion, inspect the generated typed KDL and compare all active
   settings and bindings against that reference. Serialization order and removed
   comments are not required to match.
3. Run `niri validate` against the realized typed configuration.
4. Run targeted formatting/linting for the changed Nix files.
5. Evaluate the flake and build the `pvg1-nixos` system closure.
6. Confirm the generated UWSM compositor command still points to
   `/run/current-system/sw/bin/niri-session`.

## Non-goals

- Enabling niri-flake's NixOS desktop stack or binary cache.
- Changing keybindings, window-management behavior, portals, or session startup.
- Refactoring unrelated Wayland modules.
