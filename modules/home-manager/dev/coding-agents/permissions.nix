{
  config,
  lib,
  ...
}:

let
  permCfg = config.home-manager.dev.coding-agents.permissions;
  hasContainers = permCfg.containers.enable;
  autoDiscover = permCfg.autoDiscoverPackages;
  binaryOverrides = permCfg.packageBinaryOverrides;
  extraAllowed = permCfg.allowedCommands;
  extraDenied = permCfg.deniedCommands;
  extraAllowedWriteDirectories = permCfg.allowedWriteDirectories;

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
    "sort"
    "ss"
    "stat"
    "strings"
    "tail"
    "tar"
    "test"
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

  candidateAllowedShellCommands = lib.unique (
    baseShellCommands
    ++ discoveredPackageCommands
    ++ lib.optionals hasContainers containerAllowedCommands
    ++ extraAllowed
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
    lib.optional (config.home-manager.dev.coding-agents.opencode.enable or false
    ) "${config.home.homeDirectory}/.config/opencode"
    ++ lib.optional (config.home-manager.dev.coding-agents.codex.enable or false
    ) "${config.home.homeDirectory}/.codex"
    ++ lib.optional (config.home-manager.dev.coding-agents.antigravity-cli.enable or false
    ) "${config.home.homeDirectory}/.gemini"
    ++ [ "/nix/store" ];

  allowedWriteDirectories = lib.unique (
    lib.optionals (config ? home.homeDirectory) [ config.home.homeDirectory ]
    ++ [ "/tmp" ]
    ++ extraAllowedWriteDirectories
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

    allowedWriteDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        config.home.homeDirectory
        "/tmp"
      ];
      description = "Directories where coding agents are permitted to write files (e.g. via shell redirection)";
    };

    autoDiscoverPackages = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to automatically discover executable commands from home.packages";
    };

    packageBinaryOverrides = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.str);
      default = {
        python3 = [
          "python"
          "python3"
          "python3.14"
        ];
        coreutils = [
          "cat"
          "cp"
          "date"
          "diff"
          "echo"
          "head"
          "id"
          "ls"
          "mkdir"
          "mv"
          "pwd"
          "rm"
          "sleep"
          "sort"
          "stat"
          "tail"
          "test"
          "touch"
          "tr"
          "uname"
          "uniq"
          "wc"
          "whoami"
        ];
        bun = [
          "bun"
          "bunx"
        ];
        nodejs = [
          "corepack"
          "node"
          "npm"
          "npx"
          "pnpm"
        ];
        nodejs_20 = [
          "corepack"
          "node"
          "npm"
          "npx"
          "pnpm"
        ];
        nodejs_22 = [
          "corepack"
          "node"
          "npm"
          "npx"
          "pnpm"
        ];
        findutils = [
          "find"
          "xargs"
        ];
        diffutils = [
          "diff"
          "cmp"
        ];
        gnused = [ "sed" ];
        gnugrep = [ "grep" ];
        gnumake = [ "make" ];
        go = [
          "go"
          "gofmt"
        ];
      };
      description = "Mapping of package names/pnames to the binary commands they provide";
    };

    # Computed internal options
    allowedShellCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = allowedShellCommands;
      description = "Final allowed shell commands across coding agents";
    };

    deniedShellCommands = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = deniedShellCommands;
      description = "Final denied shell commands across coding agents";
    };

    commonNetworkDomains = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = commonNetworkDomains;
      description = "Shared network domains allowed for coding agents";
    };

    commonExternalDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = commonExternalDirectories;
      description = "Shared external read-only directories across coding agents";
    };

    finalAllowedWriteDirectories = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      internal = true;
      readOnly = true;
      default = allowedWriteDirectories;
      description = "Final writable directories across coding agents";
    };
  };
}
