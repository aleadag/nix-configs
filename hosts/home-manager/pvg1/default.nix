{
  home = rec {
    username = "alexander";
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";
  };

  home-manager = {
    dev.enable = true;
    desktop.enable = true;
    mihomo.enable = false;
    nix.niks3.gc.enable = true;
    window-manager = {
      enable = true;
      x11.enable = false;
    };
  };

  targets.genericLinux = {
    enable = true;
    gpu = {
      enable = true;
      nvidia = {
        enable = true;
        version = "550.144.03";
        sha256 = "sha256-akg44s2ybkwOBzZ6wNO895nVa1KG9o+iAb49PduIqsQ=";
      };
    };
  };
}
