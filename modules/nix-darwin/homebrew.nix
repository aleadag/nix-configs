{ config, lib, ... }:

let
  cfg = config.nix-darwin.homebrew;
  podmanCfg = cfg.podman;
  inherit (config.nix-darwin.home) username;
in
{
  options.nix-darwin.homebrew = {
    enable = lib.mkEnableOption "Homebrew config" // {
      default = true;
    };

    podman.enable = lib.mkEnableOption "Podman with Docker-compatible clients" // {
      default = config.nix-darwin.homebrew.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    nix-darwin.home.extraModules = {
      home-manager.dev.coding-agents.permissions.containers.enable = podmanCfg.enable;
      home.sessionVariables.DOCKER_HOST = lib.mkIf podmanCfg.enable "unix:///var/run/docker.sock";
      programs = {
        firefox.package = lib.mkForce null;
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
        "kitty"
        "linearmouse"
        "microsoft-edge"
      ];
      brews = lib.optionals podmanCfg.enable [
        "docker"
        "docker-compose"
        "podman"
        "podman-compose"
      ];
    };

    home-manager.users.${username}.home-manager.darwin.homebrew = {
      enable = true;
      inherit (config.homebrew) prefix;
    };
  };
}
