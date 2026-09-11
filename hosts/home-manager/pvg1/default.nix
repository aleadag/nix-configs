{ flake, pkgs, ... }:
{
  stylix.image = "${pkgs.pop-wallpapers}/share/backgrounds/pop/jasper-van-der-meij-97274-edit.jpg";

  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    desktop = {
      enable = true;
      lutris.enable = true;
    };
    dev.enable = true;
    kanata.enable = false;
    mihomo.enable = false;
    nix.niks3.gc.enable = true;
    syncthing.enable = true;
    window-manager = {
      enable = true;
      wayland.swayidle.powerOffDisplays.enable = false;
    };
  };

  programs.swaylock.package = null;

  nixpkgs.config = flake.outputs.lib.internal.configs.nixpkgs // {
    cudaSupport = true;
  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "610.57.04";
        sha256 = "sha256-suk1xmuDuwDAyFe8jg7g/VLekoa0DJzB7sKafOfrEW0=";
      };
    };
  };
}
