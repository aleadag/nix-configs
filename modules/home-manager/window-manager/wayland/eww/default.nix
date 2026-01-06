{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.home-manager.window-manager.wayland.eww;
  swayCfg = config.home-manager.window-manager.wayland.sway;

  # Helper scripts
  scriptsDir = ./scripts;

  # Get stylix colors with hashtag prefix
  colorsWithHash = config.lib.stylix.colors.withHashtag;

  # Automatically discover all script files in the scripts directory
  scriptNames = builtins.attrNames (builtins.readDir scriptsDir);

  # Common dependencies for all scripts (deduplicated)
  commonScriptDeps = with pkgs; [
    # Core utilities used by multiple scripts
    coreutils
    gawk

    # Sway integration
    jq
    sway

    # Network monitoring
    networkmanager
    gnugrep
    iproute2

    # System monitoring
    procps
    systemd

    # Audio control
    wireplumber
    pamixer
    pulseaudio # For pactl subscribe in event-driven volume

    # Notifications
    dunst

    # Input method
    fcitx5

    # Other utilities
    gnused
    util-linux

    # Eww itself for idle-inhibit script
    config.programs.eww.package
  ];

  # Helper function to create eww scripts with common dependencies
  mkEwwScript =
    scriptName:
    pkgs.writeShellApplication {
      name = "eww-${scriptName}";
      runtimeInputs = commonScriptDeps;
      text = builtins.readFile (scriptsDir + "/${scriptName}");
    };

  # Generate all scripts
  scriptPackages = map mkEwwScript scriptNames;

  # Package all eww scripts into a single derivation
  eww-scripts = pkgs.symlinkJoin {
    name = "eww-scripts";
    paths = scriptPackages;
  };

  # Generate colors.scss from stylix using lib.concatMapStringsSep
  colorVars = [
    "00"
    "01"
    "02"
    "03"
    "04"
    "05"
    "06"
    "07"
    "08"
    "09"
    "0A"
    "0B"
    "0C"
    "0D"
    "0E"
    "0F"
  ];

  # Generate colors.scss content from stylix
  colorsScssContent = ''
    // Generated from stylix base16 color scheme
  ''
  + lib.concatMapStringsSep "\n" (num: "$base${num}: ${colorsWithHash."base${num}"};") colorVars;

  # Generate eww.scss with colors import prepended
  ewwScssContent = ''
    @import "colors.scss";
    ${builtins.readFile ./config/eww.scss}
  '';

  # Volume control program from config
  inherit (config.home-manager.window-manager.default) volumeControl;
in
{
  options.home-manager.window-manager.wayland.eww = {
    enable = lib.mkEnableOption "Eww config" // {
      default = config.home-manager.window-manager.wayland.enable;
    };
    battery.enable = lib.mkEnableOption "battery widget" // {
      default = config.device.type == "laptop";
    };
  };

  config = lib.mkIf cfg.enable {
    # Write config files directly to ~/.config/eww/ for stable IPC socket path
    # (eww hashes the config directory path for socket naming)
    home.file = {
      ".config/eww/colors.scss".text = colorsScssContent;
      ".config/eww/eww.scss".text = ewwScssContent;
      ".config/eww/eww.yuck".source = pkgs.substitute {
        src = ./config/eww.yuck;
        substitutions = [
          "--replace-fail"
          "eww-volume-control"
          volumeControl
        ];
      };
    };

    programs.eww = {
      enable = true;
      package = pkgs.eww;
      # configDir = null means eww uses default ~/.config/eww (managed by home.file above)
    };

    systemd.user.services.eww = {
      Unit = {
        Description = "Eww Daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe config.programs.eww.package} daemon --no-daemonize";
        Restart = "on-failure";
        # Add basic tools to PATH: sh for spawning deflisten commands, and utilities for inline commands
        Environment = [
          "PATH=${
            lib.makeBinPath (
              with pkgs;
              [
                bash # Provides 'sh' which eww uses to spawn deflisten commands
                coreutils
                gawk
                procps # Provides 'free' command for memory monitoring
                iproute2 # Provides 'ip' command for network bandwidth
                pamixer # For volume control
                dunst # For dunstctl onclick handler
              ]
              ++ [ eww-scripts ]
            )
          }:${config.home.profileDirectory}/bin"
        ];
        inherit (config.home-manager.window-manager.systemd.service)
          RestartSec
          RestartSteps
          RestartMaxDelaySec
          ;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Open the bar on startup
    wayland.windowManager.sway.config = lib.mkIf swayCfg.enable {
      startup = [
        { command = "${lib.getExe config.programs.eww.package} open bar"; }
      ];
    };
  };
}
