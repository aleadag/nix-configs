# Research: Agent Desk ownership of MCP and skills

> **Date:** 2026-07-17
> **Bead:** nix-configs-87h
> **Status:** Complete

## Summary

Agent Desk should not become the source of truth for MCP servers or the existing Codex skills yet. Keep both declarative in Home Manager, and use Agent Desk only as an optional browser/editor for mutable, non-Nix-managed agent files until it supports MCP writes and Codex `~/.codex/skills/*/SKILL.md` discovery.

## Key Findings

### Agent Desk does not currently manage MCP configuration

> **Confidence:** high — the official guide and current source agree.

Agent Desk's MCP view reads existing tool configuration and masks environment values [S1]. The backend exposes `GetMCPConfigs`, backed by `LoadAllMCPConfigs`; there are no MCP create, update, delete, or save operations [S2][S3]. Its MCP loader covers several JSON-based clients but does not include Codex's TOML configuration [S2].

Therefore, moving MCP ownership out of `programs.mcp` would not transfer it to Agent Desk; it would remove declarative ownership without gaining a replacement writer.

### Agent Desk can mutate skill files, but not the Codex skills used here

> **Confidence:** high — verified from the current scanner, classifier, and app methods.

Agent Desk edits skill files in their original tool-specific locations and can create, save, delete, enable, and disable supported files [S1][S3]. However, its Codex scanner currently recognizes `~/.codex/agents/*.toml`, `~/.codex/config.toml`, and `AGENTS.md`; it does not recognize `~/.codex/skills/*/SKILL.md` [S4][S5].

The current `pvg1` Home Manager evaluation produces seven skills under `.codex/skills/`: `commit-message`, `defuddle`, `json-canvas`, `jujutsu`, `obsidian-bases`, `obsidian-cli`, and `obsidian-markdown`. Agent Desk cannot currently discover these as Codex skills.

### Direct editing conflicts with Home Manager ownership

> **Confidence:** high — grounded in the evaluated Home Manager output and Agent Desk's write implementation.

`programs.codex.skills` renders the current skills as Home Manager-managed targets such as `.codex/skills/commit-message`, whose source evaluates to an immutable `/nix/store/...-commit-message` path. Agent Desk's save operation calls `os.WriteFile` directly on the discovered path [S3]. Such files are not an appropriate mutable ownership boundary: an edit will fail against an immutable target or be replaced by the next Home Manager activation.

### Agent Desk and Agent Deck are different layers

> **Confidence:** high — each project's own description gives it a distinct role.

This module currently installs `llm-agents.agent-deck`, a terminal session manager for coding agents [S6]. Agent Desk is a separate desktop application focused on browsing and editing agent configuration files [S1]. Replacing Agent Deck with Agent Desk is not a feature-equivalent migration; it exchanges session orchestration for configuration browsing.

## Comparisons

| Criterion | Home Manager owns MCP and skills | Agent Desk owns both | Hybrid: Nix canonical, Agent Desk optional |
|-----------|------------------------------------|-----------------------|--------------------------------------------|
| Reproducible across hosts | Yes | No declarative manifest | Yes |
| Current MCP support | Declarative generation | Read-only inspection | Nix writes; Agent Desk may inspect supported clients |
| Current Codex `SKILL.md` support | Yes | Not discovered | Nix writes; Agent Desk cannot browse them yet |
| GUI editing | Edit repository sources | Direct in-place editing | Only for explicitly unmanaged files |
| Activation conflict | None | Conflicts if paths remain Nix-managed | None when ownership is kept separate |
| Recommendation | Strong baseline | Reject for now | Recommended adoption boundary |

## Disagreements

Agent Desk's homepage describes a unified MCP view and broad Codex support [S7]. The detailed guide says the MCP panel reads configurations, while the source exposes only a getter and omits Codex from the MCP definitions [S1][S2][S3]. The source is authoritative for current behavior: “manage” currently means inspect for MCP, and Codex support does not include Codex folder skills.

## Codebase Context

- `modules/home-manager/dev/coding-agents/default.nix` installs Agent Deck, `tmux`, and `ctx7` when the coding-agent group is enabled.
- `modules/home-manager/dev/coding-agents/mcp.nix` declaratively owns the MCP registry through `programs.mcp.servers`; it currently declares Context7.
- `modules/home-manager/dev/coding-agents/codex.nix` enables MCP integration and loads pinned/shared skills from flake inputs plus the local `skills/` directory.
- `modules/home-manager/dev/coding-agents/claude-code.nix` owns Claude Code settings, context, agents, hooks, and permissions.
- `modules/home-manager/dev/coding-agents/permissions.nix` is the cross-agent permission source of truth.
- On 2026-07-17, `pvg1` evaluates both `home-manager.dev.coding-agents.mcp.enable` and `programs.mcp.enable` to `false`.

## Recommendations

1. Keep MCP servers in `mcp.nix` and continue integrating them into each enabled client through Home Manager.
2. Keep curated/shared skills in Nix and their source repositories. Do not let Agent Desk edit Home Manager-generated paths.
3. If adopting Agent Desk now, package and launch it only as an optional viewer/editor for files explicitly designated mutable and outside Home Manager ownership.
4. Do not remove Agent Deck merely because Agent Desk is adopted; decide separately whether its session-management role is still wanted.
5. Re-evaluate Agent Desk ownership only after it adds all of:
   - create/update/delete for MCP configurations, including Codex TOML;
   - discovery of Codex `~/.codex/skills/*/SKILL.md` folder skills;
   - a declarative export/import format suitable for version control;
   - clear handling for symlinked or externally managed files.

## Recommended Beads

None until the user chooses whether to install Agent Desk as an optional companion or pursue an ownership migration despite the current limitations.

## Open Questions

- Is the intended product Agent Desk (`agentdesk.sh`) or the already-installed Agent Deck session manager?
- Is GUI editing more important than Nix reproducibility for personal, mutable skills?
- Should MCP remain disabled on `pvg1`, or was the current `false` value accidental?

## Refuted / Discarded Claims

- **“Agent Desk can own MCP configuration today.”** Discarded: the current backend only reads MCP configs.
- **“Agent Desk supports the Codex skills currently produced by this module.”** Discarded: current classification does not include `.codex/skills/*/SKILL.md`.
- **“Agent Desk replaces Agent Deck.”** Discarded: they solve different problems.

## Sources

- [Agent Desk user guide](https://agentdesk.sh/help) — Primary/Official — updated April 2026 — skill editing, in-place ownership, MCP read behavior, local state.
- [Agent Desk MCP loader](https://github.com/warunacds/agentdesk/blob/main/internal/skills/mcp.go) — Primary/Official source — accessed 2026-07-17 — supported MCP config paths and read-only loader.
- [Agent Desk application methods](https://github.com/warunacds/agentdesk/blob/main/app.go) — Primary/Official source — accessed 2026-07-17 — skill mutation methods and MCP getter.
- [Agent Desk scanner](https://github.com/warunacds/agentdesk/blob/main/internal/skills/scanner.go) — Primary/Official source — accessed 2026-07-17 — scanned roots and candidate files.
- [Agent Desk classifier](https://github.com/warunacds/agentdesk/blob/main/internal/skills/classifier.go) — Primary/Official source — accessed 2026-07-17 — Codex file classification.
- [Agent Deck README](https://github.com/asheshgoplani/agent-deck) — Primary/Official — accessed 2026-07-17 — session-manager role and MCP/skill attachment model.
- [Agent Desk homepage](https://agentdesk.sh/) — Primary/Official — accessed 2026-07-17 — product positioning and supported-tool claims.
