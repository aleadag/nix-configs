{
  nixpkgs.hostPlatform = "aarch64-darwin";

  nix-darwin.home = {
    username = "alexander";
    extraModules = {
      home.stateVersion = "26.05";
      home-manager = {
        cli.zsh.zprof.enable = true;
        desktop.obsidian.enable = true;
        syncthing.enable = true;
        window-manager.paneru.enable = true;
        dev.coding-agents.coding-brain.enable = false;
        dev.podman.enable = true;
      };

      services.podman = {
        useDefaultMachine = false;

        machines.podman-machine-default = {
          autoStart = false;
          cpus = 4;
          diskSize = 100;
          memory = 8192;
          rootful = false;
          volumes = [
            "/Users:/Users"
            "/private:/private"
            "/var/folders:/var/folders"
          ];
        };
      };
    };
  };

  # This value determines the nix-darwin release with which your system is to
  # be compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after nix-darwin release notes say you
  # should.
  system.stateVersion = 6; # Did you read the comment?
}
