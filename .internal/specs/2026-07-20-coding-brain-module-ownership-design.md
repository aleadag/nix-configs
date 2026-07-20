# Coding Brain module ownership design

> Date: 2026-07-20
> Bead: `nix-configs-g9x`
> Status: Approved design

## Context

The upstream `codexctl` project renamed its binary and Home Manager option to Coding Brain. This repository currently imports that Home Manager module and configures `programs.codexctl` inside `modules/home-manager/dev/coding-agents/codex.nix`, which makes Coding Brain appear to be an implementation detail of the Codex module.

Coding Brain remains Codex-oriented today, but its upstream Home Manager module now separates package/configuration enablement from optional Codex hook integration. The local module ownership should reflect that separation without changing which hosts enable it by default.

## Goals

- Make Coding Brain a sibling coding-agent tool rather than part of the Codex module.
- Add an independently overrideable local enable option.
- Preserve the current default: Coding Brain follows the Codex enable state.
- Adopt the upstream `programs.coding-brain` option and renamed executable.
- Keep the change small and avoid unrelated input or repository renames.

## Non-goals

- Rename the flake input key or upstream GitHub repository from `codexctl`.
- Enable Coding Brain by default for hosts that do not enable Codex.
- Change Brain model, endpoint, timeout, approval, or security settings.
- Change Codex permissions, plugins, skills, hooks unrelated to Coding Brain, or package selection.

## Module ownership

`modules/home-manager/dev/coding-agents/default.nix` becomes the owner of Coding Brain integration. It will:

1. Accept the `flake` module argument.
2. Import `flake.inputs.codexctl.homeManagerModules.default` alongside the existing coding-agent module imports.
3. Define `home-manager.dev.coding-agents.coding-brain.enable` with a default of `config.home-manager.dev.coding-agents.codex.enable`.
4. Configure `programs.coding-brain` when the new local option is enabled.

The Coding Brain `lib.mkIf` must remain separate from the existing `home-manager.dev.coding-agents.enable` package block. This preserves the repository's child-option behavior: an explicit `coding-brain.enable = true` can enable Coding Brain even if the group option is disabled.

`modules/home-manager/dev/coding-agents/codex.nix` will stop importing the upstream module and will remove its `programs.codexctl` configuration. It will continue to own Codex itself, including Codex hooks that are unrelated to Coding Brain.

## Configuration

The existing settings move unchanged to `programs.coding-brain.settings.brain`:

- `enabled = true`
- `endpoint = "http://localhost:11434/api/generate"`
- `model = "gemma4:e4b"`
- `auto = false`
- `timeout_ms = 25000`
- `terminal_auto_approve_fallback = false`

The repository will not set `programs.coding-brain.codexHooks.enable` explicitly. The upstream default enables hooks only when the installed Home Manager exposes `programs.codex.hooks` and Codex itself is enabled.

## Enable behavior

| Codex enabled | Local Coding Brain override | Coding Brain | Codex hook integration |
| --- | --- | --- | --- |
| Yes | Unset | Enabled | Enabled by upstream default |
| No | Unset | Disabled | Disabled |
| No | `true` | Enabled | Disabled by upstream default |
| Yes | `false` | Disabled | Disabled |

## Flake input

Keep the input key and URL as `codexctl` because the upstream repository identity still uses that name. Update only its lock pin so this repository receives the renamed package and `programs.coding-brain` Home Manager API.

## Safety and failure behavior

- Brain settings remain non-secret because Home Manager writes them through the Nix store.
- No credentials or token-bearing URLs are added.
- Explicitly enabling Coding Brain without Codex remains valid; the upstream module installs the package and omits Codex hooks.
- Explicitly forcing Codex hooks while Codex is disabled remains guarded by upstream assertions.
- Removing the old `programs.codexctl` block prevents evaluation against the renamed upstream API.

## Validation

1. Update the `codexctl` input and confirm the locked package exposes the `coding-brain` executable.
2. Run targeted `nix eval` checks for:
   - `pvg1` Codex and Coding Brain local enables;
   - `programs.coding-brain.enable`;
   - a Codex-disabled host remaining Coding Brain-disabled by default;
   - explicit `coding-brain.enable = true` with Codex disabled by extending the `lckfb` Home Manager configuration for the evaluation.
3. Confirm generated Coding Brain settings retain all existing values.
4. Confirm Coding Brain hooks are present when Codex is enabled and absent when it is disabled.
5. Run `just lint` on `default.nix` and `codex.nix`.
6. Run a `pvg1` activation-package dry run.

## Rollback

Revert the lock update and module changes together. The previous pin expects `programs.codexctl`, while the updated pin expects `programs.coding-brain`; mixing either module configuration with the other pin is unsupported.
