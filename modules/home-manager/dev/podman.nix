{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.dev.podman;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
  isGenericLinux = pkgs.stdenv.hostPlatform.isLinux && config.targets.genericLinux.enable;
  podmanPackage = config.services.podman.package;
in
{
  options.home-manager.dev.podman.enable = lib.mkEnableOption "Podman development environment";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = isDarwin || isGenericLinux;
            message = "home-manager.dev.podman is supported only on Darwin or generic Linux";
          }
        ];

        services.podman.enable = true;

        home.packages = with pkgs; [
          docker-client
          docker-compose
        ];

        home-manager.dev.coding-agents.permissions.containers.enable = true;
      }

      (lib.mkIf isDarwin {
        assertions = [
          {
            assertion = builtins.hasAttr "podman-machine-default" config.services.podman.machines;
            message = "home-manager.dev.podman requires services.podman.machines.podman-machine-default";
          }
        ];

        home.sessionVariables.DOCKER_HOST = "unix://$TMPDIR/podman/podman-machine-default-api.sock";
      })

      (lib.mkIf isGenericLinux {
        services.podman.autoUpdate.enable = lib.mkDefault false;

        systemd.user.packages = [ podmanPackage ];
        xdg.configFile."systemd/user/sockets.target.wants/podman.socket".source =
          "${podmanPackage}/share/systemd/user/podman.socket";

        home.sessionVariables.DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
      })
    ]
  );
}
