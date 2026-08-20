# Coding-agent network domain access design

## Context

`modules/home-manager/dev/coding-agents/permissions.nix` already centralizes shell-command and external-directory permissions for Codex, Claude Code, OpenCode, and Antigravity CLI. It does not centralize network destinations. The coding agents therefore have no shared, reviewable set of development domains, and their native network controls differ.

The selected approach is to define one curated domain list and apply the strongest native enforcement each pinned backend supports. Codex and Claude Code can constrain command subprocesses by destination, and Antigravity can constrain supported web-fetch tools. Pinned OpenCode cannot express destination-specific fetch rules, and neither OpenCode nor Antigravity provides an equivalent native domain allowlist for arbitrary shell subprocesses. Their existing shell permission behavior must remain unchanged, and the configuration must not claim parity that the backends cannot enforce.

## Shared policy

Add `commonNetworkDomains` to `permissions.nix` beside `allowedShellCommands`, `deniedShellCommands`, and `commonExternalDirectories`.

The list will contain explicit apex and subdomain patterns needed for common development workflows:

- GitHub, GitHubusercontent, and GitLab;
- NixOS, nix-community, and Cachix;
- npm and Node.js;
- Go package and checksum services;
- crates.io and Rustup;
- PyPI and Python-hosted packages;
- Docker Hub, GitHub Container Registry, and Quay.

The shared policy will not include a global wildcard, localhost, literal loopback addresses, or private-network ranges. Backend renderers may translate the shared patterns into backend-specific forms, but may not broaden them.

## Backend rendering

### Codex

Codex will inherit `commonNetworkDomains`, enable command networking in the workspace-write sandbox, enable its network proxy, and render each shared pattern as an allow rule. Both command networking and the proxy are required: command networking grants connectivity, while the proxy enforces the destination rules.

This policy applies to commands and their child processes. It does not claim to constrain separately hosted search, MCP servers, connectors, browser activity, or Codex cloud environments.

### Claude Code

Claude Code will inherit `commonNetworkDomains` and render it into both `WebFetch(domain:...)` allow permissions and the sandbox network allowlist. The sandbox will use strict allowlist behavior so an unlisted command destination is denied instead of becoming a session approval.

Sandboxed commands must retain the current permission prompts rather than becoming implicitly approved merely because sandboxing is active. Unsandboxed fallback must remain disabled so a failed sandbox cannot silently bypass the network boundary.

### OpenCode

Pinned OpenCode 1.18.18 cannot express domain-specific `webfetch` rules: its parser accepts only the singular action-level `permission` object and discards the ordered `permissions` array required for resource patterns. OpenCode will therefore remain unchanged so its existing shell and directory decisions are preserved. A domain-specific policy requires a separately approved upgrade to a version whose pinned parser accepts URL-resource rules.

OpenCode shell commands run with the host user's network authority. The existing shell allow, ask, and deny rules will remain unchanged; this design does not represent them as domain-filtered.

### Antigravity CLI

Antigravity CLI will inherit `commonNetworkDomains` and render `read_url(apex)` only for explicit apex-plus-wildcard pairs. Because Antigravity's matcher also covers all subdomains, exact-only shared entries such as `production.cloudflare.docker.com` remain prompt-by-default rather than being broadened. If its pinned schema cannot express a shared rule without widening it, implementation leaves that destination unchanged and records the verified limitation.

Antigravity command permissions will remain unchanged because its native permission model does not provide a verified destination allowlist for arbitrary subprocess traffic.

## Security and failure behavior

The domain list is allowlist-oriented and intentionally omits local and private destinations. Codex and Claude Code must fail closed when their configured command-network enforcement cannot initialize; neither backend may silently retry outside its sandbox or proxy.

OpenCode and Antigravity retain their current approval behavior outside the capabilities they can filter. A backend syntax or version mismatch is a validation failure, not a reason to emit an unsupported setting.

## Validation

Validation will cover:

1. Evaluate representative Home Manager configurations and inspect the rendered settings for every enabled backend.
2. Confirm the pinned Codex and Claude Code versions accept their generated network and sandbox settings.
3. Confirm OpenCode retains its existing supported settings and Antigravity receives only settings supported by its pinned schema.
4. Verify representative allowed and unlisted domain patterns in generated configuration without making live external requests.
5. Run targeted Nix formatting, Statix, and relevant flake evaluation checks.

No live network requests, host activation, commit, or push are part of implementation without separate authorization.
