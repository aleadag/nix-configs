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
in
{
  imports = [ ./linux-builder.nix ];

  options.nix-darwin.nix = {
    enable = lib.mkEnableOption "nix/nixpkgs config" // {
      default = true;
    };
    proxy = lib.mkOption {
      default = "socks5://127.0.0.1:7890";
      example = "http://localhost:1234";
      type = with lib.types; nullOr str;
      description = "Nix daemon proxy.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      darwin-cleanup
      raycast
    ];

    nix = {
      gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };

      # Customized nixpkgs, e.g.: `nix shell nixpkgs_#snes9x`
      registry.nixpkgs_.flake = flake;

      envVars = lib.optionalAttrs (cfg.proxy != null) (
        let
          inherit (cfg) proxy;
        in
        {
          http_proxy = proxy;
          https_proxy = proxy;
        }
      );

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
        flake.inputs.nur.overlays.default
      ];
    };
  };
}
