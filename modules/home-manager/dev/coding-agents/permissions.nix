{
  config ? { },
  lib ? pkgs.lib,
  pkgs ? null,
  ...
}:

let
  permCfg = config.home-manager.dev.coding-agents.permissions or { };
  hasContainers = permCfg.containers.enable or false;
  autoDiscover = permCfg.autoDiscoverPackages or true;
  binaryOverrides = permCfg.packageBinaryOverrides or { };
  extraAllowed = permCfg.allowedCommands or [ ];
  extraDenied = permCfg.deniedCommands or [ ];

  containerDeniedCommands =
    lib.concatMap
      (
        runtime:
        map (cmd: "${runtime} ${cmd}") [
          "system prune"
          "system reset"
          "container prune"
          "image prune"
          "network prune"
          "volume prune"
          "pod prune"
          "builder prune"
          "buildx prune"
          "machine reset"
          "machine rm"
        ]
      )
      [
        "podman"
        "docker"
      ];

  # Dangerous commands that should be explicitly denied / prompted
  deniedShellCommands = lib.unique (
    [
      "rm -rf"
      "git push"
      "git reset --hard"
      "git clean"
      "jj git push"
      "bd purge"
      "nix-collect-garbage"
      "nix store delete"
      "nix-store --delete"
      "terraform apply"
      "terraform destroy"
      "sbt publish"
    ]
    ++ lib.optionals hasContainers containerDeniedCommands
    ++ extraDenied
  );

  # Base Unix and text processing builtins (always allowed)
  baseShellCommands = [
    "cat"
    "cd"
    "date"
    "diff"
    "echo"
    "file"
    "find"
    "grep"
    "head"
    "id"
    "jq"
    "ls"
    "make"
    "mkdir"
    "ps"
    "pwd"
    "rg"
    "sed"
    "sort"
    "stat"
    "tail"
    "test"
    "tree"
    "uname"
    "uniq"
    "wc"
    "which"
    "whoami"
    # Nix system tools
    "nix"
    "nix-store"
    "nix-shell"
  ];

  # Auto-discover package binaries from config.home.packages
  discoveredPackageCommands =
    if autoDiscover && (config ? home.packages) then
      lib.concatMap (
        pkg:
        let
          pname = pkg.pname or (lib.getName pkg);
        in
        binaryOverrides.${pname} or (
          if (pkg ? meta.mainProgram) && pkg.meta.mainProgram != null && pkg.meta.mainProgram != "" then
            [ pkg.meta.mainProgram ]
          else
            [ (lib.getName pkg) ]
        )
      ) config.home.packages
    else
      [ ];

  containerAllowedCommands = [
    "podman"
    "docker"
    "podman-compose"
    "docker-compose"
  ];

  allowedShellCommands = lib.unique (
    baseShellCommands
    ++ discoveredPackageCommands
    ++ lib.optionals hasContainers containerAllowedCommands
    ++ extraAllowed
  );

  # Shared canonical network domains allowed for coding agents
  commonNetworkDomains = [
    "cachix.org"
    "crates.io"
    "docker.com"
    "docker.io"
    "ghcr.io"
    "github.com"
    "githubusercontent.com"
    "gitlab.com"
    "go.dev"
    "golang.org"
    "goproxy.io"
    "nix-community.org"
    "nixos.org"
    "nodejs.org"
    "npmjs.org"
    "production.cloudflare.docker.com"
    "pypi.org"
    "pythonhosted.org"
    "quay.io"
    "rust-lang.org"
    "rustup.rs"
  ];

  # Read-only directories shared across coding agents: each agent's own config
  # (managed by Nix, so read-only) plus the immutable Nix store.
  commonExternalDirectories =
    lib.optional (config.home-manager.dev.coding-agents.opencode.enable or false
    ) "${config.home.homeDirectory}/.config/opencode"
    ++ lib.optional (config.home-manager.dev.coding-agents.codex.enable or false
    ) "${config.home.homeDirectory}/.codex"
    ++ lib.optional (config.home-manager.dev.coding-agents.antigravity-cli.enable or false
    ) "${config.home.homeDirectory}/.gemini"
    ++ [ "/nix/store" ];
in
{
  inherit
    allowedShellCommands
    commonExternalDirectories
    commonNetworkDomains
    deniedShellCommands
    ;
}
