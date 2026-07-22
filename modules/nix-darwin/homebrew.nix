{ config, lib, ... }:

let
  cfg = config.nix-darwin.homebrew;
  inherit (config.nix-darwin.home) username;
in
{
  options.nix-darwin.homebrew = {
    enable = lib.mkEnableOption "Homebrew config" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    nix-darwin.home.extraModules = {
      programs = {
        firefox.package = lib.mkForce null;
        ghostty.package = null;
        kitty.package = null;
      };
    };

    homebrew = {
      enable = true;
      casks = [
        "domzilla-caffeine"
        "feishu"
        "firefox"
        "google-chrome"
        "ghostty"
        "kitty"
        "linearmouse"
        "microsoft-edge"
      ];
    };

    home-manager.users.${username}.home-manager.darwin.homebrew = {
      enable = true;
      inherit (config.homebrew) prefix;
    };
  };
}
