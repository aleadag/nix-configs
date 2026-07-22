# Design: Shared Writable Config Activation for Coding Agents (Codex & Antigravity-CLI)

## Context & Problem
Coding agents like Codex (`config.toml`) and Antigravity-CLI (`settings.json`) require writable runtime configuration files to record user actions (such as project trust approvals, session state, UI preferences, or dynamic tokens).

By default, Home Manager creates read-only symlinks in `/nix/store`. When agents modify their configuration files or Home Manager runs repeated activations:
1. The read-only store symlinks prevent atomic updates or break symlink integrity.
2. Home Manager attempts to back up modified files to `.hm-backup`, hitting backup collision errors when `.hm-backup` files already exist.

Previously, `codex.nix` used a custom Python script (`merge-config.py`) requiring `python3.withPackages (ps: [ ps.tomlkit ])`. `antigravity-cli.nix` had no activation helper.

## Decision & Design

We will establish a unified, shared activation helper `mkWritableConfigActivation` in `modules/home-manager/dev/coding-agents/shared.nix` powered by `pkgs.yq-go`.

### Key Features
1. **`pkgs.yq-go` powered merging**:
   - Replaces custom Python scripts (`merge-config.py` deleted).
   - Supports both `json` and `toml` natively using `yq eval-all -p=<format> -o=<format> '. as $item ireduce ({}; . * $item)'`.
2. **Symlink to Writable File Conversion**:
   - Converts read-only Nix store symlinks (`/nix/store/*`) into regular files (`chmod 600`) at activation time.
3. **Automatic `.hm-backup` Cleanup & Merge**:
   - When `.hm-backup` exists, deep-merges runtime additions (e.g. trusted projects) into Home Manager baseline settings and removes the backup file cleanly.

### Components

#### 1. `shared.nix`
Exposes `mkWritableConfigActivation`:
```nix
mkWritableConfigActivation =
  {
    name,
    path,
    format ? "json", # "json" or "toml"
  }:
  lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    set -euo pipefail

    config_path="${path}"
    backup_ext="''${HOME_MANAGER_BACKUP_EXT:-}"
    backup_path="$config_path''${backup_ext:+.$backup_ext}"
    tmp="$(mktemp)"

    if [ ! -e "$config_path" ]; then
      rm -f "$tmp"
    elif [ -n "$backup_ext" ] && [ -e "$backup_path" ]; then
      ${lib.getExe pkgs.yq-go} eval-all -p=${format} -o=${format} '. as $item ireduce ({}; . * $item)' "$backup_path" "$config_path" > "$tmp"

      if ! ${pkgs.diffutils}/bin/cmp -s "$backup_path" "$tmp"; then
        echo "Merged ${name} config changes:"
        ${pkgs.diffutils}/bin/diff -u "$backup_path" "$tmp" || true
      fi

      $DRY_RUN_CMD mv "$tmp" "$config_path"
      $DRY_RUN_CMD chmod 600 "$config_path"
      $DRY_RUN_CMD rm -f "$backup_path"
    elif [ -L "$config_path" ] && [[ "$(readlink "$config_path")" == /nix/store/* ]]; then
      if [[ -v DRY_RUN ]]; then
        echo "cat '$config_path' > '$tmp'"
      else
        cat "$config_path" > "$tmp"
      fi

      $DRY_RUN_CMD mv "$tmp" "$config_path"
      $DRY_RUN_CMD chmod 600 "$config_path"
    else
      rm -f "$tmp"
    fi
  '';
```

#### 2. `codex.nix`
Replaces custom python setup with:
```nix
home.activation.mergeCodexConfig = lib.mkIf (isTomlConfig && config.programs.codex.settings != { }) (
  shared.mkWritableConfigActivation {
    name = "Codex";
    path = codexConfigPath;
    format = "toml";
  }
);
```

#### 3. `antigravity-cli.nix`
Adds activation helper:
```nix
home.activation.makeAntigravitySettingsWritable = lib.mkIf (config.programs.antigravity-cli.settings != { }) (
  shared.mkWritableConfigActivation {
    name = "Antigravity CLI";
    path = "${config.home.homeDirectory}/.gemini/antigravity-cli/settings.json";
    format = "json";
  }
);
```

#### 4. Clean up `merge-config.py`
Remove `modules/home-manager/dev/coding-agents/merge-config.py`.

## Verification Plan
1. Run `just lint` (format & statix check).
2. Run `nix flake check` / build home manager activation package dry-run.
3. Test `yq-go` merge behavior on sample TOML and JSON files.

## Stress Test Results: Shared Writable Config Activation

### Resolved Decisions
- **Array Merging Behavior**: `yq-go` overlay arrays replace baseline arrays, ensuring Home Manager remains the single source of truth for declarative lists (skills, plugins), while merging dictionary keys.
- **Security & Permissions**: `chmod 600` is enforced on merged target files to protect sensitive tokens or secrets in `settings.json` / `config.toml`. All filesystem mutations are wrapped in `$DRY_RUN_CMD`.
- **Legacy Cleanup**: `modules/home-manager/dev/coding-agents/merge-config.py` will be deleted during implementation.

### Changes Made
- Confirmed design using `pkgs.yq-go` for both `.json` and `.toml` formats in `shared.mkWritableConfigActivation`.

### Deferred / Parking Lot
- None.

### Confidence Assessment
- Overall: High
- Areas of concern: None.

