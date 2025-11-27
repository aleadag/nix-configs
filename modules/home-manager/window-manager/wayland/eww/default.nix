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

  colors-scss = pkgs.writeText "colors.scss" (
    ''
      // Generated from stylix base16 color scheme
    ''
    + lib.concatMapStringsSep "\n" (num: "$base${num}: ${colorsWithHash."base${num}"};") colorVars
  );

  # Use substituteAll for more declarative config generation
  ewwConfigDir = pkgs.stdenv.mkDerivation {
    name = "eww-config";
    src = ./config;

    nativeBuildInputs = [ pkgs.gnused ];

    inherit (config.home-manager.window-manager.default) volumeControl;

    buildPhase = ''
      # Copy colors.scss
      cp ${colors-scss} colors.scss

      # Add import statement to eww.scss
      sed -i '1i@import "colors.scss";' eww.scss

      # Replace volume control placeholder with configured program
      substituteInPlace eww.yuck \
        --replace-fail "eww-volume-control" "$volumeControl"
    '';

    installPhase = ''
      mkdir -p $out
      cp -r . $out/
    '';
  };
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
    programs.eww = {
      enable = true;
      package = pkgs.eww;
      configDir = ewwConfigDir;
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
