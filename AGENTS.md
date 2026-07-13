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

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:970c3bf2 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Agent Context Profiles

The managed Beads block is task-tracking guidance, not permission to override repository, user, or orchestrator instructions.

- **Conservative (default)**: Use `bd` for task tracking. Do not run git commits, git pushes, or Dolt remote sync unless explicitly asked. At handoff, report changed files, validation, and suggested next commands.
- **Minimal**: Keep tool instruction files as pointers to `bd prime`; use the same conservative git policy unless active instructions say otherwise.
- **Team-maintainer**: Only when the repository explicitly opts in, agents may close beads, run quality gates, commit, and push as part of session close. A current "do not commit" or "do not push" instruction still wins.

## Session Completion

This protocol applies when ending a Beads implementation workflow. It is subordinate to explicit user, repository, and orchestrator instructions.

1. **File issues for remaining work** - Create beads for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **Handle git/sync by active profile**:
   ```bash
   # Conservative/minimal/default: report status and proposed commands; wait for approval.
   git status

   # Team-maintainer opt-in only, unless current instructions forbid it:
   git pull --rebase
   bd dolt push
   git push
   git status
   ```
5. **Hand off** - Summarize changes, validation, issue status, and any blocked sync/commit/push step

**Critical rules:**
- Explicit user or orchestrator instructions override this Beads block.
- Do not commit or push without clear authority from the active profile or the current user request.
- If a required sync or push is blocked, stop and report the exact command and error.
<!-- END BEADS INTEGRATION -->
