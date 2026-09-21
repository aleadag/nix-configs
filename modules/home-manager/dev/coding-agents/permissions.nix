{
  config,
  lib,
  ...
}:

let
  agentsCfg = config.home-manager.dev.coding-agents;
  permCfg = agentsCfg.permissions;
  hasContainers = permCfg.containers.enable;
  extraAllowed = permCfg.allowedCommands;
  extraDenied = permCfg.deniedCommands;

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

  deniedShellCommands = lib.unique (
    [
      "rm -rf"
      "mkfs"
      "git push"
      "git reset --hard"
      "git clean"
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

  baseShellCommands = [
    "cat"
    "cd"
    "command"
    "cp"
    "cut"
    "date"
    "df"
    "diff"
    "du"
    "echo"
    "file"
    "find"
    "grep"
    "gzip"
    "head"
    "hostname"
    "id"
    "jq"
    "ls"
    "make"
    "man"
    "mkdir"
    "mv"
    "pgrep"
    "printf"
    "ps"
    "pwd"
    "rg"
    "read"
    "readlink"
    "realpath"
    "sed"
    "sha256sum"
    "shasum"
    "sleep"
    "sort"
    "ss"
    "stat"
    "strings"
    "tail"
    "tar"
    "test"
    "touch"
    "tr"
    "tree"
    "type"
    "uname"
    "uniq"
    "wc"
    "which"
    "whoami"
    "nix"
    "nix-build"
    "nix-store"
    "nix-shell"
  ];

  containerAllowedCommands = [
    "podman"
    "docker"
    "podman-compose"
    "docker-compose"
  ];

  candidateAllowedShellCommands = lib.unique (
    baseShellCommands ++ lib.optionals hasContainers containerAllowedCommands ++ extraAllowed
  );

  allowedShellCommands = lib.subtractLists deniedShellCommands candidateAllowedShellCommands;

  commonNetworkDomains = [
    "brew.sh"
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

  commonExternalDirectories =
    lib.optional agentsCfg.opencode.enable "${config.xdg.configHome}/opencode"
    ++ lib.optional agentsCfg.codex.enable (
      if config.home.preferXdgDirectories then
        "${config.xdg.configHome}/codex"
      else
        "${config.home.homeDirectory}/.codex"
    )
    ++ lib.optional agentsCfg.antigravity-cli.enable "${config.home.homeDirectory}/.gemini"
    ++ [ "/nix/store" ];

  allowedWriteDirectories = lib.unique (
    [
      config.home.homeDirectory
      "/tmp"
    ]
    ++ permCfg.extraAllowedWriteDirectories
  );
in
{
  options.home-manager.dev.coding-agents.permissions = {
    containers.enable = lib.mkEnableOption "Podman-backed container command permissions";

    allowedCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra shell commands permitted across coding agents";
    };

    deniedCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra dangerous commands explicitly denied across coding agents";
    };

    extraAllowedWriteDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional directories where coding agents may write (always includes $HOME and /tmp)";
    };

    allowedShellCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Final allowed shell commands across coding agents";
    };

    deniedShellCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Final denied shell commands across coding agents";
    };

    commonNetworkDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Shared network domains allowed for coding agents";
    };

    commonExternalDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Shared external read-only directories across coding agents";
    };

    finalAllowedWriteDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      description = "Final writable directories across coding agents";
    };
  };

  config.home-manager.dev.coding-agents.permissions = {
    inherit
      allowedShellCommands
      deniedShellCommands
      commonNetworkDomains
      commonExternalDirectories
      ;
    finalAllowedWriteDirectories = allowedWriteDirectories;
  };
}
