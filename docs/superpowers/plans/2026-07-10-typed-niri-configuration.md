# Typed Niri Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the raw Home Manager Niri KDL document with validated typed `programs.niri.settings` backed by niri-flake's unstable Niri package.

**Architecture:** Add `niri-flake` as a Home Manager schema, package overlay, and Stylix provider while retaining the repository's NixOS/UWSM integration. The existing Home Manager module will derive typed settings from repository options and package paths, `homeModules.stylix` will supply Stylix defaults such as the cursor and border colors, and the config module imported by `homeModules.niri` will serialize and validate the resulting KDL.

**Tech Stack:** Nix flakes, NixOS modules, Home Manager modules, niri-flake, UWSM, Jujutsu

## Global Constraints

- Use `pkgs.niri-unstable` and `pkgs.xwayland-satellite-unstable` from `niri.overlays.niri` for managed Home Manager sessions.
- Import `niri.homeModules.niri` and `niri.homeModules.stylix`, disabling the Niri Stylix target on non-Linux systems; do not enable niri-flake's NixOS or binary-cache modules.
- Preserve UWSM, portal, keyring, power-menu, startup, input, rule, and keybinding behavior while enabling integrated Xwayland Satellite.
- Preserve the QWERTY and Page Up/Page Down workspace policy in `docs/keybinding-conventions.md`.
- Remove only raw-KDL comments, commented examples, empty nodes, and disabled rules with no runtime effect.
- Use `pvg1-nixos` as the representative Niri-enabled host.

---

### Task 1: Capture the Existing Generated Configuration

**Files:**
- Read: `modules/home-manager/window-manager/wayland/niri.nix`
- Reference: `docs/keybinding-conventions.md`
- Artifact: `/tmp/niri-config-before` (Nix result symlink, not committed)

**Interfaces:**
- Consumes: `nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.xdg.configFile."niri/config.kdl".source`
- Produces: a realized pre-migration KDL reference used for semantic comparison

- [ ] **Step 1: Realize the current generated KDL**

Run:

```bash
nix build --out-link /tmp/niri-config-before '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.xdg.configFile."niri/config.kdl".source'
```

Expected: exit 0 and `/tmp/niri-config-before` points to the validated current `niri-config.kdl` store path.

- [ ] **Step 2: Confirm the reference contains repository-specific behavior**

Run:

```bash
rg -n 'workspace-auto-back-and-forth|Mod\+Q|Mod\+Shift\+P|spawn-at-startup|Picture-in-Picture' /tmp/niri-config-before
```

Expected: all five patterns are present.

---

### Task 2: Add the niri-flake Modules and Package Overlay

**Files:**
- Modify: `flake.nix:72`
- Modify: `flake.lock`
- Modify: `overlays/default.nix`

**Interfaces:**
- Consumes: existing `nixpkgs` and `nixpkgs-stable` inputs
- Produces: `flake.inputs.niri.homeModules.niri`, `flake.inputs.niri.homeModules.stylix`, and the Niri package overlay

- [ ] **Step 1: Add the flake input**

Insert after the `paneru` input in `flake.nix`:

```nix
niri = {
  url = "github:sodiboo/niri-flake";
  inputs = {
    nixpkgs.follows = "nixpkgs";
    nixpkgs-stable.follows = "nixpkgs-stable";
  };
};
```

- [ ] **Step 2: Apply the package overlay**

Apply `inputs.niri.overlays.niri` in `overlays/default.nix` so the unstable Niri
and Xwayland Satellite packages are available through the repository package set.

- [ ] **Step 3: Lock the new input**

Run:

```bash
nix flake lock --update-input niri
```

Expected: `flake.lock` gains `niri`, its Niri/Xwayland sources, and required transitive nodes without updating unrelated root inputs.

- [ ] **Step 4: Verify the modules and overlay are available**

Run:

```bash
nix flake metadata --json | jq -e '.locks.nodes.niri.locked.rev'
```

Expected: exit 0 with the locked niri-flake revision.

- [ ] **Step 5: Format and inspect the dependency change**

Run:

```bash
just lint flake.nix overlays/default.nix
jj --no-pager diff --git
```

Expected: formatted Nix and a diff limited to the input, lock nodes, and package overlay.

- [ ] **Step 6: Record the dependency revision and start the configuration revision**

Run:

```bash
jj desc -m "❄️ build: add niri-flake config module"
jj new -m "♻️ refactor(niri): use typed Home Manager settings"
```

Expected: the dependency changes remain in the parent and the new working-copy revision is empty.

---

### Task 3: Convert the Home Manager Module to Typed Settings

**Files:**
- Modify: `modules/home-manager/window-manager/wayland/niri.nix:1-742`
- Verify: `modules/nixos/window-manager/wayland.nix:65-120`

**Interfaces:**
- Consumes: `flake.inputs.niri.homeModules.niri`, `flake.inputs.niri.homeModules.stylix`, `pkgs.niri-unstable`, `pkgs.xwayland-satellite-unstable`, repository keyboard/default-app/Stylix options, and executable paths
- Produces: `programs.niri.package` and a complete `programs.niri.settings` value

- [ ] **Step 1: Import the typed Home Manager schema and Stylix adapter**

Add `flake` to the Home Manager module arguments and import the full Home Manager and Stylix modules. The explicit Stylix import is required because this repository imports Stylix inside Home Manager and disables its NixOS-to-Home-Manager auto-import. Disable its Niri target on non-Linux systems because the shared Home Manager module also evaluates on Darwin:

```nix
{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
```

```nix
imports = [
  flake.inputs.niri.homeModules.niri
  flake.inputs.niri.homeModules.stylix
];

config = lib.mkMerge [
  (lib.mkIf (!pkgs.stdenv.hostPlatform.isLinux) {
    stylix.targets.niri.enable = false;
  })
  (lib.mkIf cfg.enable {
    # Niri configuration
  })
];
```

Keep `imports` at module top level and keep the non-Linux Stylix guard outside the Niri enable branch.

- [ ] **Step 2: Select the managed unstable Niri package**

Change the custom package default to:

```nix
default = pkgs.niri-unstable;
defaultText = lib.literalExpression "pkgs.niri-unstable";
```

Inside the enabled Home Manager configuration set:

```nix
programs.niri = {
  package = if cfg.package != null then cfg.package else pkgs.niri;
  enable = cfg.package != null;
  settings = typedSettings;
};

systemd.user.packages = lib.optional (cfg.package != null) cfg.package;
```

Leave the NixOS Niri launcher references as `pkgs.niri`. The UWSM `binPath`
remains `/run/current-system/sw/bin/niri-session`, while Home Manager exposes the
selected managed package's `niri.service`.

- [ ] **Step 3: Define typed input, layout, rule, and environment settings**

Create `typedSettings` in the Home Manager module `let` expression. It must contain these exact effective values:

```nix
typedSettings = {
  input = {
    keyboard = {
      numlock = true;
      xkb =
        lib.optionalAttrs (layout != null) { inherit layout; }
        // lib.optionalAttrs (variant != null) { inherit variant; }
        // lib.optionalAttrs (xkbOptions != "") { options = xkbOptions; };
    };
    touchpad = {
      tap = true;
      dwt = true;
      natural-scroll = true;
      scroll-method = "two-finger";
      middle-emulation = true;
    };
    mouse.accel-profile = "flat";
    workspace-auto-back-and-forth = true;
  };
  layout = {
    gaps = 8;
    center-focused-column = "always";
    preset-column-widths = map (proportion: { inherit proportion; }) [ 0.33333 0.5 0.66667 ];
    default-column-width.proportion = 0.66667;
    focus-ring = {
      enable = true;
      width = 2;
    };
    border = {
      enable = false;
      width = 2;
    };
    shadow = {
      enable = false;
      softness = 30;
      spread = 5;
      offset = { x = 0; y = 5; };
    };
  };
  hotkey-overlay.skip-at-startup = true;
  screenshot-path = "~/Pictures/Screenshots/%Y-%m-%d_%H-%M-%S-screenshot.png";
  window-rules = [
    {
      matches = [ { app-id = "firefox$"; title = "^Picture-in-Picture$"; } ];
      open-floating = true;
    }
  ];
  environment = {
    NIXOS_OZONE_WL = "1";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
  } // lib.optionalAttrs (config.i18n.inputMethod.enable && config.i18n.inputMethod.type == "fcitx5") {
    XMODIFIERS = "@im=fcitx";
  };
  spawn-at-startup = [
    { sh = "xrdb -merge ~/.Xresources"; }
    { argv = [ (lib.getExe pkgs.swaybg) "-i" (toString config.stylix.image) "-m" wallpaperMode ]; }
  ];
  xwayland-satellite = {
    enable = true;
    path = lib.getExe pkgs.xwayland-satellite-unstable;
  };
};
```

The omitted focus-ring, urgent-border, and shadow colors match the pinned Niri
defaults; Stylix continues to supply active and inactive border colors. If the
current niri-flake type names differ during evaluation, use the documented typed
equivalent; do not fall back to `programs.niri.config` or raw KDL.

- [ ] **Step 4: Translate every active keybinding**

Define each binding under `typedSettings.binds`. Use `action.<name>` for the action, plus `repeat`, `cooldown-ms`, `allow-inhibiting`, `allow-when-locked`, and `hotkey-overlay.title` where present.

The binding map must include these exact groups:

| Keys | Typed actions and metadata |
| --- | --- |
| `Mod+Ctrl+Slash` | `show-hotkey-overlay` |
| `Mod+D`, `Mod+Return`, `Mod+M` | `spawn-sh` with menu, terminal, browser; retain overlay titles |
| `Mod+Shift+Escape` | `spawn` power menu; title `Power Menu`; `allow-inhibiting = false` |
| `Super+Alt+L` | `spawn` loginctl plus `lock-session`; title `Lock the Screen`; `allow-inhibiting = false` |
| `XF86Audio*`, `XF86MonBrightness*` | current `spawn-sh` command strings; `allow-when-locked = true` |
| `Mod+S`, `Mod+Shift+Slash` | `toggle-overview`, `close-window`; `repeat = false` |
| Arrow and HJKL focus/move chords | current focus-column/window and move-column/window actions |
| Home/End chords | focus first/last and move column first/last |
| Ctrl+Arrow/HJKL | move workspace to monitor in the named direction |
| Ctrl+Shift+Arrow/HJKL | focus monitor in the named direction |
| Page Up/Page Down | focus workspace up/down; shifted forms move column up/down |
| Wheel chords | current focus/move actions; preserve `cooldown-ms = 150` on vertical workspace chords |
| `Mod+Q..P` | `focus-workspace` arguments 1 through 10 |
| `Mod+Shift+Q..P` | `move-column-to-workspace` arguments 1 through 10 |
| `Mod+Tab` | `focus-workspace-previous`; title `Switch Focus Between Workspaces` |
| Brackets | consume-or-expel window left/right |
| Period/height/layout chords | current preset width/height, reset, maximize, fullscreen, expand, and center actions |
| Minus/Equal chords | `set-column-width` or `set-window-height` with current percentage strings |
| Floating/tabbed chords | current toggle floating/focus and tabbed-display actions |
| Print chords | screenshot, screenshot-screen, screenshot-window |
| `Mod+Escape` | `toggle-keyboard-shortcuts-inhibit`; `allow-inhibiting = false` |
| `Ctrl+Alt+Delete`, `Mod+Shift+Alt+P` | quit and power-off-monitors |

Use generated Nix attrsets only for the two QWERTY workspace ranges when doing so keeps the key-to-index mapping explicit. All other bindings remain individually named for maintenance clarity.

- [ ] **Step 5: Remove raw-KDL generation**

Delete:

- `quote = builtins.toJSON`;
- the entire `xdg.configFile."niri/config.kdl".source = pkgs.writeTextFile { ... };` block;
- all sample comments, commented KDL, empty animation/strut/window-rule nodes, and disabled example rules.

Retain systemd user package exposure, the power-menu helper, `layout`, `variant`, `xkbOptions`, default apps, and wallpaper-derived values used by typed settings.

- [ ] **Step 6: Format and evaluate the typed module**

Run:

```bash
just lint modules/home-manager/window-manager/wayland/niri.nix modules/nixos/window-manager/wayland.nix
nix eval '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.programs.niri.finalConfig' --apply 'config: config != null'
```

Expected: formatting succeeds and the evaluation returns `true`.

---

### Task 4: Validate Semantic Parity and the Built System

**Files:**
- Verify: `flake.nix`
- Verify: `flake.lock`
- Verify: `modules/home-manager/window-manager/wayland/niri.nix`
- Verify: `modules/nixos/window-manager/wayland.nix`
- Verify: `docs/keybinding-conventions.md`
- Artifact: `/tmp/niri-config-after` (Nix result symlink, not committed)

**Interfaces:**
- Consumes: the typed Home Manager configuration and its selected Niri package
- Produces: validated generated KDL and a buildable `pvg1-nixos` system closure

- [ ] **Step 1: Realize the typed generated KDL**

Run:

```bash
nix build --out-link /tmp/niri-config-after '.#nixosConfigurations.pvg1-nixos.config.home-manager.users.alexander.xdg.configFile.niri-config.source'
```

Expected: exit 0; niri-flake's validation has accepted the generated file.

- [ ] **Step 2: Validate directly with the selected package**

Run:

```bash
$(nix build --no-link --print-out-paths '.#legacyPackages.x86_64-linux.niri-unstable')/bin/niri validate --config /tmp/niri-config-after
```

Expected: exit 0 with a valid configuration result.

- [ ] **Step 3: Compare all active behavior**

Run:

```bash
diff -u /tmp/niri-config-before /tmp/niri-config-after
```

Expected: textual differences are allowed because comments and serialization order change. Review every differing active node and confirm there is no missing input, layout, startup, environment, window-rule, or binding behavior.

Run focused policy checks:

```bash
rg -n 'Mod\+Q|Mod\+P|Mod\+Shift\+Q|Mod\+Shift\+P|Mod\+Page_Down|Mod\+Shift\+Page_Down' /tmp/niri-config-after
```

Expected: all six representative bindings are present with the same actions as `docs/keybinding-conventions.md`.

- [ ] **Step 4: Confirm UWSM ownership remains intact**

Run:

```bash
nix eval --raw '.#nixosConfigurations.pvg1-nixos.config.programs.uwsm.waylandCompositors.niri.binPath'
```

Expected: `/run/current-system/sw/bin/niri-session`.

- [ ] **Step 5: Run repository gates**

Run:

```bash
just lint flake.nix modules/home-manager/window-manager/wayland/niri.nix modules/nixos/window-manager/wayland.nix
just test flake.nix modules/home-manager/window-manager/wayland/niri.nix modules/nixos/window-manager/wayland.nix
nix build '.#nixosConfigurations.pvg1-nixos.config.system.build.toplevel' --dry-run
```

Expected: all commands exit 0. The dry run evaluates the complete system and reports only required realizations/substitutions.

- [ ] **Step 6: Review the final revisions**

Run:

```bash
jj --no-pager st
jj --no-pager diff --git -r @-
jj --no-pager diff --git -r @
```

Expected: the PR changeset contains the niri-flake dependency and overlay, typed Niri module migration, and matching documentation. No unrelated files are modified.
