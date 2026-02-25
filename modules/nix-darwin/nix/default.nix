{
  config,
  lib,
  libEx,
  flake,
  pkgs,
  ...
}:

let
  cfg = config.nix-darwin.nix;
  inherit (config.nix-darwin.home) username;
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
    ./linux-builder.nix
  ];

  options.nix-darwin.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
    proxy = lib.mkOption {
      default = "http://127.0.0.1:7890";
      example = "http://localhost:1234";
      type = with lib.types; nullOr str;
      description = "Nix daemon proxy.";
    };
    awsCredentialsFile = lib.mkOption {
      default = hmAwsCredentialsFile;
      example = "/Users/alexander/.config/niks3/aws_credentials";
      type = with lib.types; nullOr str;
      description = "AWS credentials file path for nix-daemon.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      darwin-cleanup
    ];

    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };

      # Customized nixpkgs, e.g.: `nix shell nixpkgs_#snes9x`
      registry.nixpkgs_.flake = flake;

      envVars = lib.mkMerge [
        (lib.optionalAttrs (cfg.proxy != null) (
          let
            inherit (cfg) proxy;
          in
          {
            http_proxy = proxy;
            https_proxy = proxy;
          }
        ))
        (lib.optionalAttrs (cfg.awsCredentialsFile != null) {
          AWS_SHARED_CREDENTIALS_FILE = cfg.awsCredentialsFile;
        })
      ];

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
            "@admin"
          ];
        }
      ];
    };

    nixpkgs = {
      config = flake.outputs.internal.configs.nixpkgs;
      overlays = [
        flake.outputs.overlays.default
      ];
    };
  };
}
