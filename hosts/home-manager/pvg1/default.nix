{
  flake,
  lib,
  pkgs,
  ...
}:
{
  stylix.image = "${pkgs.pop-wallpapers}/share/backgrounds/pop/nasa-89127.jpg";

  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.11";
  };

  home-manager = {
    desktop = {
      enable = true;
      lutris.enable = true;
    };
    dev = {
      enable = true;
      coding-agents.agent-steward.autoApprove = true;
      coding-agents.collie = {
        enable = true;
        publicHosts = [ "pvg1.tailbea285.ts.net" ];
      };
    };
    kanata.enable = false;
    mihomo.enable = false;
    nix.niks3.gc.enable = true;
    syncthing.enable = true;
    window-manager = {
      enable = true;
      wayland.swayidle.powerOffDisplays.enable = false;
    };
  };

  # cudaSupport is on for this host, so ollama compiles GGML/llama.cpp with nvcc.
  # nixpkgs defaults `cudaArches` to sm_75..sm_121, so every ggml-cuda template
  # instance is compiled for 10 targets: ~8min here on 32 cores, ~2h48m in CI.
  # This GPU is RTX 4090 D (compute_cap 8.9). Keep this in sync if the GPU changes;
  # an unmatched arch silently falls back to CPU inference.
  services.ollama.package = pkgs.ollama.override {
    cudaArches = [ "sm_89" ];
  };

  programs.swaylock.package = null;

  nix.settings = {
    cores = 16;
    max-jobs = lib.mkForce 2;
  };

  nixpkgs.config = flake.outputs.lib.internal.configs.nixpkgs // {
    cudaSupport = true;
  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "620.70.06";
        sha256 = "sha256-KRGOOr0IwHVZvMo9nHYjjQOUkK8DYqLlvPy+cgSv1LE=";
      };
    };
  };
}
