{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nixpkgs.config.permittedInsecurePackages = [
    "openclaw-2026.2.26"
  ];

  nix-darwin.home = {
    username = "alexander";
    extraModules = {
      home.stateVersion = "26.05";
      home-manager = {
        dev.node.enable = false;
        desktop.mpv.enable = false;
        openclaw.enable = true;
        syncthing.enable = false;
        window-manager.paneru.enable = false;
      };
    };
  };

  nix-darwin = {
    homebrew.enable = false;
  };

  # This value determines the nix-darwin release with which your system is to
  # be compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after nix-darwin release notes say you
  # should.
  system.stateVersion = 6; # Did you read the comment?
}
