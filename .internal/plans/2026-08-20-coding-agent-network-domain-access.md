# Coding-agent Network Domain Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use beads-superpowers:subagent-driven-development (recommended) or beads-superpowers:executing-plans to implement this plan task-by-task. Each Task becomes a bead (`bd create -t task --parent <epic-id>`). Steps within tasks use checkbox (`- [ ]`) syntax for human readability.

**Goal:** Add one curated common-development domain policy, render the strongest supported enforcement for Codex, Claude Code, and Antigravity CLI, and preserve OpenCode's pinned supported policy.

**Architecture:** `permissions.nix` owns backend-neutral host patterns. Codex and Claude Code enforce command egress and web access, while Antigravity pre-approves only wildcard-backed `read_url` destinations without claiming command-egress filtering. Pinned OpenCode 1.18.18 remains unchanged because it cannot express destination-specific fetch rules without discarding its existing shell and directory policy.

**Tech Stack:** Nix, Home Manager modules, Codex TOML, Claude Code JSON, OpenCode 1.18.18 permissions, Antigravity CLI permissions, Statix, treefmt/nixfmt.

## Global Constraints

- Keep changes within `modules/home-manager/dev/coding-agents/` plus the approved design and plan artifacts.
- Do not add a global network wildcard, localhost, loopback addresses, or private-network ranges.
- Backend renderers may translate shared patterns but may not broaden them.
- Preserve existing shell approval decisions; Claude sandboxing must not auto-approve commands.
- OpenCode and Antigravity shell subprocesses must not be described as domain-filtered.
- Do not make live network requests, activate a host, commit, or push without separate authorization.
- Link the implementation epic to design bead `nix-configs-4p7d` with a `discovered-from` dependency.

---

### Task 1: Define the shared domain policy

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/permissions.nix`

**Interfaces:**
- Consumes: the existing shared-permission module.
- Produces: `commonNetworkDomains :: [ string ]` for every backend renderer.

**Acceptance Criteria:**
- `permissions.nix` exports `commonNetworkDomains` beside the existing shell and directory values.
- The list covers the development ecosystems named in the design.
- Exact apex entries accompany wildcard subdomain entries.
- The list contains neither `"*"` nor local/private destinations.

- [ ] **Step 1: Verify the interface is initially absent**

Run: `rg -n 'commonNetworkDomains' modules/home-manager/dev/coding-agents/permissions.nix`

Expected: exit status 1 with no matches.

- [ ] **Step 2: Add and export the shared list**

Insert this value immediately before `commonExternalDirectories`:

```nix
  # Network domains shared across coding agents. Exact apex entries accompany
  # wildcard entries because backend wildcard semantics exclude the apex.
  commonNetworkDomains = [
    "cachix.org"
    "*.cachix.org"
    "crates.io"
    "*.crates.io"
    "docker.com"
    "*.docker.com"
    "docker.io"
    "*.docker.io"
    "github.com"
    "*.github.com"
    "githubusercontent.com"
    "*.githubusercontent.com"
    "gitlab.com"
    "*.gitlab.com"
    "golang.org"
    "*.golang.org"
    "go.dev"
    "*.go.dev"
    "goproxy.io"
    "*.goproxy.io"
    "ghcr.io"
    "*.ghcr.io"
    "nix-community.org"
    "*.nix-community.org"
    "nixos.org"
    "*.nixos.org"
    "nodejs.org"
    "*.nodejs.org"
    "npmjs.org"
    "*.npmjs.org"
    "production.cloudflare.docker.com"
    "pypi.org"
    "*.pypi.org"
    "pythonhosted.org"
    "*.pythonhosted.org"
    "quay.io"
    "*.quay.io"
    "rust-lang.org"
    "*.rust-lang.org"
    "rustup.rs"
    "*.rustup.rs"
  ];
```

Add `commonNetworkDomains` to the final export:

```nix
  inherit
    allowedShellCommands
    commonExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;
```

- [ ] **Step 3: Verify formatting and representative invariants**

Run:

```bash
nixfmt --check modules/home-manager/dev/coding-agents/permissions.nix
rg -n 'commonNetworkDomains|"github.com"|"\*\.github.com"|production\.cloudflare\.docker\.com' modules/home-manager/dev/coding-agents/permissions.nix
```

Expected: both commands exit 0 and `rg` finds the definition, representative entries, and export.

- [ ] **Step 4: Review the scoped diff**

Run:

```bash
git diff --check -- modules/home-manager/dev/coding-agents/permissions.nix
git diff -- modules/home-manager/dev/coding-agents/permissions.nix
```

Expected: no whitespace errors and only the shared list/export diff. Do not commit without separate authorization.

---

### Task 2: Enforce native command networking in Codex and Claude Code

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/codex.nix`
- Modify: `modules/home-manager/dev/coding-agents/claude-code.nix`

**Interfaces:**
- Consumes: `shared.permissions.commonNetworkDomains` from Task 1.
- Produces: Codex proxy/domain settings and Claude WebFetch plus strict sandbox settings.

**Acceptance Criteria:**
- Codex command networking is enabled only together with its network proxy.
- Every shared pattern renders as a Codex `allow` rule.
- Claude receives shared patterns through WebFetch permissions and sandbox `allowedDomains`.
- Claude uses strict allowlisting, fails if sandboxing is unavailable, forbids unsandboxed retry, and preserves command prompts.

- [ ] **Step 1: Run failing settings evaluations**

Run:

```bash
nix eval --json '.#homeConfigurations.home-mac.config.programs.codex.settings.features.network_proxy.domains'
nix eval --json '.#homeConfigurations.home-mac.config.programs.claude-code.settings.sandbox.network.allowedDomains'
```

Expected: both evaluations fail because these settings are absent.

- [ ] **Step 2: Render the Codex policy**

Expand the inherited values and derive the domain map:

```nix
  inherit (shared.permissions)
    allowedShellCommands
    commonNetworkDomains
    deniedShellCommands
    ;

  codexNetworkDomains = lib.genAttrs commonNetworkDomains (lib.const "allow");
```

Extend the existing settings:

```nix
        features = {
          apps = false;
          code_mode_host = true;
          hooks = true;
          memories = true;
          network_proxy = {
            enabled = true;
            domains = codexNetworkDomains;
          };
        };
        sandbox_workspace_write.network_access = true;
```

- [ ] **Step 3: Render the Claude policy**

Add `commonNetworkDomains` to the existing inherited values, replace the current `claudeFullPermissions` binding, and add:

```nix
  claudeAllowedNetworkPermissions = map (domain: "WebFetch(domain:${domain})") commonNetworkDomains;
  claudeFullPermissions =
    claudeAllowedBashPermissions ++ claudeAllowedNetworkPermissions ++ basicToolPermissions;
```

Add this sibling of `permissions` under `settings`:

```nix
        sandbox = {
          enabled = true;
          failIfUnavailable = true;
          allowUnsandboxedCommands = false;
          autoAllowBashIfSandboxed = false;
          network = {
            allowedDomains = commonNetworkDomains;
            strictAllowlist = true;
          };
        };
```

- [ ] **Step 4: Verify rendered settings**

Run:

```bash
nix eval --json '.#homeConfigurations.home-mac.config.programs.codex.settings.features.network_proxy' | jq -e '.enabled == true and .domains["github.com"] == "allow" and .domains["*.github.com"] == "allow"'
nix eval --json '.#homeConfigurations.home-mac.config.programs.codex.settings.sandbox_workspace_write.network_access'
nix eval --json '.#homeConfigurations.home-mac.config.programs.claude-code.settings' | jq -e '.sandbox.enabled == true and .sandbox.failIfUnavailable == true and .sandbox.allowUnsandboxedCommands == false and .sandbox.autoAllowBashIfSandboxed == false and .sandbox.network.strictAllowlist == true and (.sandbox.network.allowedDomains | index("github.com") != null) and (.permissions.allow | index("WebFetch(domain:github.com)") != null)'
```

Expected: the jq checks print `true`, the Codex network evaluation prints `true`, and every command exits 0.

- [ ] **Step 5: Review the scoped diff**

Run:

```bash
git diff --check -- modules/home-manager/dev/coding-agents/codex.nix modules/home-manager/dev/coding-agents/claude-code.nix
git diff -- modules/home-manager/dev/coding-agents/codex.nix modules/home-manager/dev/coding-agents/claude-code.nix
```

Expected: only shared-domain rendering and sandbox settings. Do not commit without separate authorization.

---

### Task 3: Add URL permissions for Antigravity and preserve OpenCode

**Files:**
- Modify: `modules/home-manager/dev/coding-agents/antigravity-cli.nix`
- Verify unchanged: `modules/home-manager/dev/coding-agents/opencode.nix`

**Interfaces:**
- Consumes: all shared permission lists.
- Produces: Antigravity `read_url(domain)` allows.

**Acceptance Criteria:**
- OpenCode retains its existing singular shell and directory permission policy because pinned 1.18.18 cannot express URL-specific `webfetch` resources.
- Antigravity adds one `read_url(apex)` rule per explicit apex-plus-wildcard pair; exact-only destinations remain prompt-by-default.
- Neither backend configures shell subprocess domain filtering.

- [ ] **Step 1: Run the failing Antigravity evaluation and OpenCode preservation check**

Run:

```bash
nix eval --json '.#homeConfigurations.home-mac.config.programs.antigravity-cli.permissions.allow' | jq -e 'index("read_url(github.com)") != null'
nix eval --json '.#homeConfigurations.home-mac.config.programs.opencode.settings.permission.bash' | jq -e '."*" == "ask" and (."git status*".data // ."git status*") == "allow" and (."rm -rf*".data // ."rm -rf*") == "deny"'
```

Expected: Antigravity prints `false` and exits non-zero; the OpenCode preservation check prints `true` and exits 0.

- [ ] **Step 2: Add Antigravity URL reads**

Add `commonNetworkDomains` to the inherited values, then define:

```nix
  networkDomains =
    lib.unique (map (lib.removePrefix "*.") (lib.filter (lib.hasPrefix "*.") commonNetworkDomains));
  allowedNetworkReads = map (domain: "read_url(${domain})") networkDomains;
```

Extend the allow value:

```nix
        allow = allowedCommands ++ directoryPermissions ++ allowedNetworkReads;
```

- [ ] **Step 3: Verify supported decisions**

Run:

```bash
nix eval --json '.#homeConfigurations.home-mac.config.programs.antigravity-cli.permissions.allow' | jq -e 'index("read_url(github.com)") != null and index("read_url(*.github.com)") == null and index("read_url(production.cloudflare.docker.com)") == null'
nix eval --json '.#homeConfigurations.home-mac.config.programs.opencode.settings.permission.bash' | jq -e '."*" == "ask" and (."git status*".data // ."git status*") == "allow" and (."rm -rf*".data // ."rm -rf*") == "deny"'
```

Expected: both checks print `true` and exit 0.

Confirm the pinned OpenCode version that motivated the approved fallback:

```bash
opencode --version
```

Expected: `1.18.18`. The tagged schema supports only singular action-level `permission`, so no OpenCode module change is allowed in this task.

- [ ] **Step 4: Review the scoped diff**

Run:

```bash
git diff --check -- modules/home-manager/dev/coding-agents/opencode.nix modules/home-manager/dev/coding-agents/antigravity-cli.nix
git diff -- modules/home-manager/dev/coding-agents/opencode.nix modules/home-manager/dev/coding-agents/antigravity-cli.nix
```

Expected: OpenCode has no diff; Antigravity only adds `read_url` rules. Do not commit without separate authorization.

---

### Task 4: Run cross-backend validation

**Files:**
- Verify: `modules/home-manager/dev/coding-agents/permissions.nix`
- Verify: `modules/home-manager/dev/coding-agents/codex.nix`
- Verify: `modules/home-manager/dev/coding-agents/claude-code.nix`
- Verify: `modules/home-manager/dev/coding-agents/opencode.nix`
- Verify: `modules/home-manager/dev/coding-agents/antigravity-cli.nix`

**Interfaces:**
- Consumes: generated settings from Tasks 1-3.
- Produces: fresh format, lint, evaluation, policy, and diff evidence.

**Acceptance Criteria:**
- Targeted formatting and Statix checks pass.
- Representative Home Manager configurations evaluate.
- Codex and Claude render command enforcement; Antigravity renders supported URL permissions; OpenCode retains its existing supported policy.
- The final diff contains no unrelated changes or whitespace errors.

- [ ] **Step 1: Run targeted formatting and lint checks**

Run:

```bash
nix fmt -- --ci modules/home-manager/dev/coding-agents/permissions.nix modules/home-manager/dev/coding-agents/codex.nix modules/home-manager/dev/coding-agents/claude-code.nix modules/home-manager/dev/coding-agents/opencode.nix modules/home-manager/dev/coding-agents/antigravity-cli.nix
for file in modules/home-manager/dev/coding-agents/{permissions,codex,claude-code,opencode,antigravity-cli}.nix; do
  statix check "$file" || exit $?
done
```

Expected: both commands exit 0.

- [ ] **Step 2: Evaluate representative configurations**

Run:

```bash
nix eval --raw '.#homeConfigurations.home-mac.activationPackage.drvPath'
nix eval --raw '.#homeConfigurations.macmini53.activationPackage.drvPath'
```

Expected: two derivation paths and exit status 0.

- [ ] **Step 3: Check cross-backend evidence**

First verify that the pinned Codex and Claude Code binaries load the network-setting shapes without starting a session. `codex doctor` may still exit non-zero for unrelated host diagnostics, so inspect its structured configuration check:

```bash
codex -c 'sandbox_workspace_write.network_access=true' -c 'features.network_proxy.enabled=true' -c 'features.network_proxy.domains={"github.com"="allow"}' doctor --json 2>/dev/null | jq -e '.checks["config.load"].status == "ok" and (.checks["config.load"].details["enabled feature flags"] | contains("network_proxy")) and .checks["sandbox.helpers"].details["network sandbox"] == "enabled"'
claude_output=$(claude --settings '{"sandbox":{"enabled":true,"failIfUnavailable":true,"allowUnsandboxedCommands":false,"autoAllowBashIfSandboxed":false,"network":{"allowedDomains":["github.com"],"strictAllowlist":true}}}' doctor)
if printf '%s\n' "$claude_output" | rg -q '^Invalid settings$'; then
  exit 1
fi
```

Expected: the Codex predicate prints `true`, and Claude emits no `Invalid settings` section. Deliberately wrong types for these known keys must make Codex report `config.load = fail` and Claude print `Invalid settings`, confirming the probes exercise validation rather than an early version exit.

Then inspect the combined Home Manager output:

Run:

```bash
nix eval --json '.#homeConfigurations.home-mac.config' --apply 'config: {
  codexNetwork = config.programs.codex.settings.sandbox_workspace_write.network_access;
  codexGithub = config.programs.codex.settings.features.network_proxy.domains."github.com";
  claudeStrict = config.programs.claude-code.settings.sandbox.network.strictAllowlist;
  claudeGithub = builtins.elem "WebFetch(domain:github.com)" config.programs.claude-code.settings.permissions.allow;
  opencodePreserved = let
    bash = config.programs.opencode.settings.permission.bash;
    unwrap = value: value.data or value;
  in bash."*" == "ask"
    && unwrap bash."git status*" == "allow"
    && unwrap bash."rm -rf*" == "deny";
  antigravityGithub = builtins.elem "read_url(github.com)" config.programs.antigravity-cli.permissions.allow;
}'
```

Expected:

```json
{"antigravityGithub":true,"claudeGithub":true,"claudeStrict":true,"codexGithub":"allow","codexNetwork":true,"opencodePreserved":true}
```

- [ ] **Step 4: Inspect the final worktree diff**

Run:

```bash
git diff --check
git status --short
git diff --stat
git diff -- modules/home-manager/dev/coding-agents/permissions.nix modules/home-manager/dev/coding-agents/codex.nix modules/home-manager/dev/coding-agents/claude-code.nix modules/home-manager/dev/coding-agents/opencode.nix modules/home-manager/dev/coding-agents/antigravity-cli.nix
```

Expected: no whitespace errors; only the four implementation modules and approved `.internal` artifacts are changed. Report validation and Beads status, then wait for separate commit or push authorization.
