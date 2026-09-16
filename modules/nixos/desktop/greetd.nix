{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixos.desktop.greetd.enable = lib.mkEnableOption "greetd config" // {
    default = config.nixos.desktop.enable;
  };

  config = lib.mkIf config.nixos.desktop.greetd.enable {
    boot = {
      consoleLogLevel = lib.mkDefault 3;
      kernelParams = [
        # Force kernel log in tty1, otherwise it will override greetd
        "console=tty1"
      ];
    };

    services = {
      # Configure greetd, a lightweight session manager
      greetd = {
        enable = true;
        settings = {
          default_session =
            let
              inherit (config.services.displayManager.sessionData) desktops;
            in
            {
              command = lib.escapeShellArgs [
                (lib.getExe pkgs.tuigreet)
                "--remember"
                "--remember-session"
                "--time"
                "--theme"
                "border=blue;title=magenta;greet=white;prompt=white;text=gray;input=gray;action=blue;button=magenta;time=gray;container=black"
                "--sessions"
                "${lib.concatStringsSep ":" (
                  builtins.map (path: "${desktops}/${path}") [
                    "share/xsessions"
                    "share/wayland-sessions"
                  ]
                )}"
              ];
            };
        };
      };
    };
  };
}
