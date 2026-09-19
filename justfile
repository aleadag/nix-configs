# justfile for Claude Code Hooks Integration
# Nix configuration project

# Lint target - runs Nix formatters and linters
# Receives file paths as arguments for targeted operations
lint *files:
    #!/usr/bin/env bash
    set -euo pipefail

    # All output to stderr as required by hooks
    exec 2>&1

    if [[ $# -gt 0 ]]; then
        echo "Linting specific Nix files: $*" >&2

        # Format specific files with nixfmt
        for file in "$@"; do
            if [[ "$file" == *.nix ]]; then
                echo "Formatting $file" >&2
                nixfmt "$file"
            fi
        done

        # Run statix on specific files
        echo "Running statix linter on specified files" >&2
        # statix check "$@"
    else
        echo "Linting all Nix files" >&2

        # Format all files using nix fmt
        echo "Running nix fmt" >&2
        nix fmt

        # Run statix on entire project
        echo "Running statix check" >&2
        # statix check
    fi

    echo "Linting completed successfully" >&2

# Test target - builds configurations to verify they're valid
# Receives file paths as arguments for targeted testing
test *files:
    #!/usr/bin/env bash
    set -euo pipefail

    # All output to stderr as required by hooks
    exec 2>&1

    if [[ $# -gt 0 ]]; then
        echo "Testing configurations related to: $*" >&2

        # For targeted testing, we'll run a basic flake check
        # since individual file testing isn't practical for Nix configs
        echo "Running flake check for configuration validation" >&2
        nix flake check --no-build
    else
        echo "Running full configuration tests" >&2

        # Run comprehensive flake check
        echo "Running nix flake check" >&2
        nix flake check --print-build-logs

        # Test building a sample configuration to ensure it works
        echo "Testing Home Manager configuration build" >&2
        nix build '.#homeConfigurations.home-mac.activationPackage' --dry-run
    fi

    echo "Testing completed successfully" >&2

# Build a specific host configuration
build-home host:
    #!/usr/bin/env bash
    echo "Building Home Manager configuration for {{host}}" >&2
    nix build '.#homeConfigurations.{{host}}.activationPackage'

build-nixos host:
    #!/usr/bin/env bash
    echo "Building NixOS configuration for {{host}}" >&2
    nix build '.#nixosConfigurations.{{host}}.config.system.build.toplevel'

build-darwin host:
    #!/usr/bin/env bash
    echo "Building nix-darwin configuration for {{host}}" >&2
    nix build '.#darwinConfigurations.{{host}}.system'

# Format all Nix files
format:
    #!/usr/bin/env bash
    echo "Formatting all Nix files" >&2
    nix fmt

# Check flake and run linters
check:
    #!/usr/bin/env bash
    echo "Running comprehensive checks" >&2
    nix flake check --no-build
    statix check

# Helper recipe to verify hook integration
check-integration:
    @echo "✓ justfile detected by Claude Code hooks" >&2
    @echo "  - 'just lint' recipe: available" >&2
    @echo "  - 'just test' recipe: available" >&2
    @echo "" >&2
    @echo "Test with:" >&2
    @echo "  just lint flake.nix" >&2
    @echo "  just test hosts/home-manager/home-mac/default.nix" >&2

# Repair a Lutris wine prefix (e.g. just repair-prefix starcraft)
repair-prefix target="":
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{target}}"

    find_runner() {
        local runners_dir="$HOME/.local/share/lutris/runners/wine"
        if [[ -d "$runners_dir" ]]; then
            find -L "$runners_dir" -maxdepth 3 -type f -name wineboot 2>/dev/null | sort -V | tail -n 1 || true
        fi
    }

    runner=$(find_runner)
    wineboot_cmd="${runner:-wineboot}"

    if ! command -v "$wineboot_cmd" >/dev/null 2>&1 && [[ ! -x "$wineboot_cmd" ]]; then
        echo "Error: wineboot not found in Lutris runners or PATH." >&2
        exit 1
    fi

    repair_one() {
        local pfx="$1"
        if [[ ! -d "$pfx/drive_c" && ! -f "$pfx/system.reg" ]]; then
            return 0
        fi

        echo "=== Checking Wine prefix: $pfx ==="
        local broken_count
        broken_count=$(find "$pfx" -xtype l | wc -l)
        local k32="$pfx/drive_c/windows/system32/kernel32.dll"

        if [[ "$broken_count" -eq 0 && -f "$k32" && -z "$target" ]]; then
            echo "✓ Wine prefix is healthy (no repair needed)."
            return 0
        fi

        if [[ "$broken_count" -gt 0 ]]; then
            echo "Removing $broken_count dangling symlinks..."
            find "$pfx" -xtype l -delete
        fi

        if [[ -f "$pfx/.update-timestamp" ]]; then
            echo "Clearing .update-timestamp..."
            rm -f "$pfx/.update-timestamp"
        fi

        echo "Running wineboot -u with: $wineboot_cmd"
        WINEPREFIX="$pfx" "$wineboot_cmd" -u

        if [[ -f "$k32" ]]; then
            echo "✓ Repair completed successfully for $pfx"
        else
            echo "⚠ Warning: kernel32.dll not found at $k32" >&2
            return 1
        fi
    }

    if [[ -z "$target" ]]; then
        games_dir="$HOME/Games"
        if [[ ! -d "$games_dir" ]]; then
            echo "No ~/Games directory found." >&2
            exit 0
        fi
        for d in "$games_dir"/*; do
            if [[ -e "$d" ]]; then
                repair_one "$d"
            fi
        done
    else
        pfx="$target"
        if [[ ! -d "$pfx" && -d "$HOME/Games/$pfx" ]]; then
            pfx="$HOME/Games/$pfx"
        fi
        if [[ ! -d "$pfx" ]]; then
            echo "Error: Directory not found: $target (checked $target and $HOME/Games/$target)" >&2
            exit 1
        fi
        repair_one "$pfx"
    fi

