{
  config,
  lib,
  libEx,
  pkgs,
  flake,
  ...
}:

let
  cfg = config.nixos.nix;
  inherit (config.nixos.home) username;
  hmAwsCredentialsFile = lib.attrByPath [
    "home-manager"
    "users"
    username
    "sops"
    "templates"
    "niks3-aws-credentials"
    "path"
  ] null config;
in
{
  imports = [
    ./diff.nix
    ./remote-builders.nix
  ];

  options.nixos.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
    tmpOnDisk = lib.mkEnableOption "set nix's TMPDIR to /var/tmp (disk instead tmpfs)" // {
      default = config.boot.tmp.useTmpfs;
    };
    awsCredentialsFile = lib.mkOption {
      default = hmAwsCredentialsFile;
      example = "/home/alexander/.config/niks3/aws_credentials";
      type = with lib.types; nullOr str;
      description = "AWS credentials file path for nix-daemon.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ nixos-cleanup ];

    nix = {
      gc = {
        automatic = true;
        persistent = true;
        randomizedDelaySec = "15m";
        dates = "3:15";
        options = "--delete-older-than 7d";
      };
      # Optimise nix-store via service
      optimise.automatic = true;
      # Reduce disk usage
      daemonIOSchedClass = "best-effort";
      daemonIOSchedPriority = 7;
      # Leave nix builds as a background task
      daemonCPUSchedPolicy = "batch";

      # Customized nixpkgs, e.g.: `nix shell nixpkgs_#snes9x`
      registry.nixpkgs_.flake = flake;

      settings = lib.mkMerge [
        # Needs to use substituters/trusted-public-keys otherwise it doesn't
        # work in nix-daemon
        (libEx.translateKeys {
          "extra-substituters" = "substituters";
          "extra-trusted-public-keys" = "trusted-public-keys";
        } flake.outputs.internal.configs.nix)
        {
          trusted-users = [
            "root"
            "@wheel"
          ];
          auto-optimise-store = true;
        }
      ];
    };

    nixpkgs = {
      config = flake.outputs.internal.configs.nixpkgs;
      overlays = [ flake.outputs.overlays.default ];
    };

    # Change build dir to /var/tmp
    systemd.services.nix-daemon = {
      environment = lib.mkMerge [
        (lib.optionalAttrs cfg.tmpOnDisk {
          TMPDIR = "/var/tmp";
        })
        (lib.optionalAttrs (cfg.awsCredentialsFile != null) {
          AWS_SHARED_CREDENTIALS_FILE = cfg.awsCredentialsFile;
        })
      ];
    };
  };
}
