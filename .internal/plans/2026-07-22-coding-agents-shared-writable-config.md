# Shared Writable Config Activation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Refactor coding agents (Codex and Antigravity-CLI) to use a shared activation helper `shared.mkWritableConfigActivation` powered by `pkgs.yq-go` for merging writable TOML and JSON configuration files cleanly.

**Architecture:** Add `mkWritableConfigActivation` in `modules/home-manager/dev/coding-agents/shared.nix`, update `codex.nix` and `antigravity-cli.nix` to consume it, delete redundant `merge-config.py`, and verify using `just lint` and Nix dry-run activation.

**Tech Stack:** Nix, Home Manager DAG activation hooks, `pkgs.yq-go`.

## Global Constraints

- Use `pkgs.yq-go` for merging both `.json` and `.toml` format configurations.
- Enforce `chmod 600` on generated target files.
- All filesystem mutations must be wrapped in `$DRY_RUN_CMD`.
- `just lint` must pass after all changes.

---

### Task 1: Add `shared.mkWritableConfigActivation` to `shared.nix`

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/shared.nix`

**Interfaces:**
- Produces: `shared.mkWritableConfigActivation { name, path, format }`

**Acceptance Criteria:**
- `shared.nix` exports `mkWritableConfigActivation` taking `name`, `path`, and `format` ("json" or "toml").
- Uses `${lib.getExe pkgs.yq-go}` to perform `eval-all` deep merging when `.hm-backup` exists.
- Converts store symlinks to regular `chmod 600` files.

- [ ] **Step 1: Edit `shared.nix` to add `mkWritableConfigActivation`**

Add `mkWritableConfigActivation` to the returned attrset in `modules/home-manager/dev/coding-agents/shared.nix`.

- [ ] **Step 2: Verify `shared.nix` formatting**

Run: `nix fmt`
Expected: Formatting clean with zero errors.

- [ ] **Step 3: Commit**

```bash
git add modules/home-manager/dev/coding-agents/shared.nix
git commit -m "✨ feat(coding-agents): add shared mkWritableConfigActivation helper"
```

---

### Task 2: Refactor `codex.nix` to use `shared.mkWritableConfigActivation` and delete `merge-config.py`

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/codex.nix`
- Delete: `modules/home-manager/dev/coding-agents/merge-config.py`

**Interfaces:**
- Consumes: `shared.mkWritableConfigActivation`
- Produces: Updated `home.activation.mergeCodexConfig` using `shared.mkWritableConfigActivation`

**Acceptance Criteria:**
- `codex.nix` uses `shared.mkWritableConfigActivation` with `format = "toml"`.
- `merge-config.py` and python `tomlkit` references are removed.
- `git rm modules/home-manager/dev/coding-agents/merge-config.py`.

- [ ] **Step 1: Update `codex.nix`**

Replace `home.activation.mergeCodexConfig` in `codex.nix` to call `shared.mkWritableConfigActivation`. Remove unused `mergeTomlScript` and `tomlMergePython` bindings.

- [ ] **Step 2: Delete `merge-config.py`**

Run: `git rm modules/home-manager/dev/coding-agents/merge-config.py`

- [ ] **Step 3: Run linter**

Run: `just lint`
Expected: Linting completed successfully.

- [ ] **Step 4: Commit**

```bash
git add modules/home-manager/dev/coding-agents/codex.nix
git commit -m "♻️ refactor(coding-agents): use shared yq-go activation helper in codex.nix"
```

---

### Task 3: Update `antigravity-cli.nix` to enable writable config activation

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/antigravity-cli.nix`

**Interfaces:**
- Consumes: `shared.mkWritableConfigActivation`
- Produces: `home.activation.makeAntigravitySettingsWritable`

**Acceptance Criteria:**
- `antigravity-cli.nix` adds `home.activation.makeAntigravitySettingsWritable` using `shared.mkWritableConfigActivation` with `format = "json"`.
- `just lint` passes cleanly.

- [ ] **Step 1: Update `antigravity-cli.nix`**

Add `home.activation.makeAntigravitySettingsWritable` to `antigravity-cli.nix`.

- [ ] **Step 2: Run linter and check evaluation**

Run: `just lint`
Expected: Linting completed successfully.

- [ ] **Step 3: Commit**

```bash
git add modules/home-manager/dev/coding-agents/antigravity-cli.nix
git commit -m "✨ feat(coding-agents): add yq-go writable config activation for antigravity-cli"
```

---

### Task 4: Full Validation & Verification

**Files:**
- Test: Full Nix flake checks and home-manager dry-run build

**Acceptance Criteria:**
- `just lint` passes.
- `nix flake check` or targeted dry-run build evaluates cleanly without errors.

- [ ] **Step 1: Run full validation**

Run: `just lint && nix flake check`
Expected: Verification clean.

- [ ] **Step 2: Commit & update bead status**

```bash
git commit --allow-empty -m "✅ test(coding-agents): verify shared yq-go activation configuration"
```
