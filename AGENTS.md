# Repository Guidelines

## Project Structure & Module Organization
This repository contains Nix flake-based system and user configuration.
- `flake.nix`, `flake.lock`: flake inputs/outputs and pinned dependencies.
- `hosts/`: per-host configs, split by platform (`home-manager/`, `nix-darwin/`, `nixos/`).
- `modules/`: reusable modules by platform plus `shared/`.
- `lib/`: helper functions and flake utilities.
- `overlays/`, `packages/`: custom packages and overlays.
- `configs/`: base configuration snippets.
- `actions/`: GitHub Actions Nix files.
- `treefmt.nix`, `statix.toml`: formatting and lint configuration.

## Build, Test, and Development Commands
Use the flake or `justfile` helpers:
- `nix develop`: enter the dev shell with Nix tooling.
- `nix fmt`: format all Nix files using treefmt.
- `statix check`: run Nix linting.
- `nix flake check`: validate flake outputs.
- `just lint [files...]`: format + lint (targeted or full).
- `just test [files...]`: flake check and optional sample build.
- `nix build '.#nixosConfigurations.<host>.config.system.build.toplevel'`
- `nix run '.#homeActivations/<host>' --accept-flake-config`

## Coding Style & Naming Conventions
- Formatting is enforced by `nix fmt` (treefmt + nixfmt).
- Prefer `nixfmt` output over manual alignment.
- Use kebab-case for host and module directories (e.g., `home-mac`, `nixos/jetson-nixos`).
- Use clear module file names like `default.nix`, `hardware.nix`, `desktop.nix`.

## Testing Guidelines
There is no dedicated unit test framework; validation is via flake checks.
- Run `nix flake check` or `just test` before changes.
- For targeted confidence, build a relevant host config:
  `nix build '.#homeConfigurations.home-mac.activationPackage' --dry-run`

## Commit & Pull Request Guidelines
Recent commits follow a lightweight convention:
- Emoji + type prefix is common (e.g., `✨ feat: ...`, `♻️ refactor(scope): ...`).
- Dependency bumps often use `flake.lock: Update`.
Keep commits scoped and include context in the PR description (host, module, or platform).

## Security & Configuration Tips
- Treat `secrets/` as sensitive; do not add plaintext secrets.
- Keep host-specific overrides in `hosts/<platform>/<host>/` and shared logic in `modules/`.
