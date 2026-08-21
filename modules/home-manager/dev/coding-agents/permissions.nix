{
  config ? { },
  lib ? pkgs.lib,
  pkgs ? null,
  ...
}:

let
  # Direct access to home-manager options with fallback to false
  hasJujutsu = config.home-manager.cli.jujutsu.enable or false;
  hasGit = (config.home-manager.cli.git.enable or false) || (config.home-manager.dev.enable or false);
  hasBeads = config.home-manager.dev.coding-agents.enable or false;
  hasJust = config.home-manager.dev.enable or false;
  hasGo = config.home-manager.dev.go.enable or false;
  hasNode = config.home-manager.dev.node.enable or false;
  hasNix = (config.home-manager.dev.nix.enable or false) || (config.home-manager.dev.enable or false);
  hasGh = config.home-manager.cli.git.gh.enable or false;
  hasContainers = config.home-manager.dev.coding-agents.permissions.containers.enable or false;
  hasCodex = config.home-manager.dev.coding-agents.codex.enable or false;
  hasOpencode = config.home-manager.dev.coding-agents.opencode.enable or false;
  hasAntigravity = config.home-manager.dev.coding-agents.antigravity-cli.enable or false;

  # Dangerous commands that should be explicitly denied
  deniedShellCommands = [
    "rm -rf"
    "git push --force"
    "git reset --hard"
    "git clean -f"
    "terraform apply"
    "terraform destroy"
    "sbt publish"
  ]
  ++ lib.optionals hasContainers containerDeniedCommands;

  # Base Unix and text processing tools (always allowed)
  baseCommands = [
    "cat"
    "cd"
    "date"
    "echo"
    "ls"
    "find"
    "file"
    "grep"
    "head"
    "jq"
    "tail"
    "wc"
    "pwd"
    "rg"
    "sed"
    "stat"
    "which"
    "test"
    "tree"
    "mkdir"
    "sort"
    "uniq"
    "diff"
    "make"
  ];

  bdCommands = [
    "bd blocked"
    "bd children"
    "bd close"
    "bd comment"
    "bd comments"
    "bd context"
    "bd create"
    "bd dep"
    "bd doctor"
    "bd dolt"
    "bd export"
    "bd import"
    "bd info"
    "bd link"
    "bd list"
    "bd memories"
    "bd note"
    "bd prime"
    "bd priority"
    "bd ready"
    "bd recall"
    "bd recompute-blocked"
    "bd remember"
    "bd reopen"
    "bd search"
    "bd show"
    "bd status"
    "bd update"
    "bd version"
  ];

  gitCommands = [
    "git add"
    "git branch"
    "git commit"
    "git diff"
    "git fetch"
    "git log"
    "git ls-files"
    "git ls-remote"
    "git remote -v"
    "git rev-parse"
    "git show"
    "git stash list"
    "git status"
  ];

  jjCommands = [
    "jj abandon"
    "jj bookmark"
    "jj commit"
    "jj desc"
    "jj describe"
    "jj diff"
    "jj git"
    "jj log"
    "jj new"
    "jj root"
    "jj show"
    "jj status"
  ];

  justCommands = [
    "just build"
    "just lint"
    "just test"
    "just fmt"
  ];

  goCommands = [
    "go build"
    "go test"
    "go vet"
    "go fmt"
    "go mod tidy"
  ];

  nodeCommands = [
    "npm run"
    "npm test"
    "npm install"
    "npm ci"
    "npx"
    "node"
  ];

  nixCommands = [
    "nix build"
    "nix flake"
    "nix develop"
    "nix fmt"
    "nix eval"
    "nix log"
    "nix path-info"
    "nix search"
    "nix-store"
    "nixfmt"
    "statix check"
  ];

  ghCommands = [
    "gh auth"
    "gh pr"
    "gh issue"
    "gh repo view"
    "gh run"
  ];

  commonContainerAllowedCommands = [
    "ps"
    "images"
    "inspect"
    "logs"
    "info"
    "version"
    "port"
    "top"
    "stats"
    "container inspect"
    "container ls"
    "image inspect"
    "image ls"
    "network inspect"
    "network ls"
    "volume inspect"
    "volume ls"
    "system df"
  ];

  commonContainerDeniedCommands = [
    "system prune"
    "container prune"
    "image prune"
    "network prune"
    "volume prune"
  ];

  containerAllowedCommands =
    lib.concatMap (runtime: map (command: "${runtime} ${command}") commonContainerAllowedCommands) [
      "podman"
      "docker"
    ]
    ++ map (command: "podman ${command}") [
      "pod inspect"
      "pod ps"
      "machine inspect"
      "machine list"
    ]
    ++ [
      "podman-compose --version"
      "docker-compose version"
    ];

  containerDeniedCommands =
    lib.concatMap (runtime: map (command: "${runtime} ${command}") commonContainerDeniedCommands) [
      "podman"
      "docker"
    ]
    ++ map (command: "podman ${command}") [
      "system reset"
      "pod prune"
      "machine reset"
      "machine rm"
    ]
    ++ map (command: "docker ${command}") [
      "builder prune"
      "buildx prune"
    ];

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

  # Read-only directories shared across coding agents: each agent's own config
  # (managed by Nix, so read-only) plus the immutable Nix store.
  commonExternalDirectories =
    lib.optional hasOpencode "${config.home.homeDirectory}/.config/opencode"
    ++ lib.optional hasCodex "${config.home.homeDirectory}/.codex"
    ++ lib.optional hasAntigravity "${config.home.homeDirectory}/.gemini"
    ++ [ "/nix/store" ];

  # Combine allowed commands gated by home-manager module availability
  allowedShellCommands =
    baseCommands
    ++ lib.optionals hasBeads bdCommands
    ++ lib.optionals hasGit gitCommands
    ++ lib.optionals hasJujutsu jjCommands
    ++ lib.optionals hasJust justCommands
    ++ lib.optionals hasGo goCommands
    ++ lib.optionals hasNode nodeCommands
    ++ lib.optionals hasNix nixCommands
    ++ lib.optionals hasGh ghCommands
    ++ lib.optionals hasContainers containerAllowedCommands;
in
{
  inherit
    allowedShellCommands
    commonExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;
}
