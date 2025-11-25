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

  # Create helper scripts using writeShellApplication
  eww-workspace-script = pkgs.writeShellApplication {
    name = "eww-workspace";
    runtimeInputs = with pkgs; [
      jq
      sway
    ];
    text = builtins.readFile (scriptsDir + /workspace);
  };

  eww-mode-script = pkgs.writeShellApplication {
    name = "eww-mode";
    runtimeInputs = with pkgs; [
      jq
      sway
    ];
    text = builtins.readFile (scriptsDir + /mode);
  };

  eww-battery-script = pkgs.writeShellApplication {
    name = "eww-battery";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile (scriptsDir + /battery);
  };

  eww-wifi-script = pkgs.writeShellApplication {
    name = "eww-wifi";
    runtimeInputs = with pkgs; [
      networkmanager
      coreutils
      gnugrep
    ];
    text = builtins.readFile (scriptsDir + /wifi);
  };

  eww-wifi-tooltip-script = pkgs.writeShellApplication {
    name = "eww-wifi-tooltip";
    runtimeInputs = with pkgs; [
      networkmanager
      coreutils
      gnugrep
      iproute2
    ];
    text = builtins.readFile (scriptsDir + /wifi-tooltip);
  };

  eww-volume-script = pkgs.writeShellApplication {
    name = "eww-volume";
    runtimeInputs = with pkgs; [
      wireplumber
      pamixer
    ];
    text = builtins.readFile (scriptsDir + /volume);
  };

  eww-disk-script = pkgs.writeShellApplication {
    name = "eww-disk";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnused
    ];
    text = builtins.readFile (scriptsDir + /disk);
  };

  eww-dunst-script = pkgs.writeShellApplication {
    name = "eww-dunst";
    runtimeInputs = with pkgs; [ dunst ];
    text = builtins.readFile (scriptsDir + /dunst);
  };

  eww-cpu-script = pkgs.writeShellApplication {
    name = "eww-cpu";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile (scriptsDir + /cpu);
  };

  eww-memory-script = pkgs.writeShellApplication {
    name = "eww-memory";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile (scriptsDir + /memory);
  };

  eww-temperature-script = pkgs.writeShellApplication {
    name = "eww-temperature";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
    ];
    text = builtins.readFile (scriptsDir + /temperature);
  };

  eww-calendar-script = pkgs.writeShellApplication {
    name = "eww-calendar";
    runtimeInputs = with pkgs; [ util-linux ];
    text = builtins.readFile (scriptsDir + /calendar);
  };

  eww-volume-scroll-script = pkgs.writeShellApplication {
    name = "eww-volume-scroll";
    runtimeInputs = with pkgs; [ pamixer ];
    text = builtins.readFile (scriptsDir + /volume-scroll);
  };

  ewwConfigDir = pkgs.runCommand "eww-config" { } ''
    cp -r ${./config} $out
    chmod -R +w $out

    # Replace all @baseXX color references with actual hex colors from stylix
    sed -i 's|@base00|${colorsWithHash.base00}|g' $out/eww.scss
    sed -i 's|@base01|${colorsWithHash.base01}|g' $out/eww.scss
    sed -i 's|@base02|${colorsWithHash.base02}|g' $out/eww.scss
    sed -i 's|@base03|${colorsWithHash.base03}|g' $out/eww.scss
    sed -i 's|@base04|${colorsWithHash.base04}|g' $out/eww.scss
    sed -i 's|@base05|${colorsWithHash.base05}|g' $out/eww.scss
    sed -i 's|@base06|${colorsWithHash.base06}|g' $out/eww.scss
    sed -i 's|@base07|${colorsWithHash.base07}|g' $out/eww.scss
    sed -i 's|@base08|${colorsWithHash.base08}|g' $out/eww.scss
    sed -i 's|@base09|${colorsWithHash.base09}|g' $out/eww.scss
    sed -i 's|@base0A|${colorsWithHash.base0A}|g' $out/eww.scss
    sed -i 's|@base0B|${colorsWithHash.base0B}|g' $out/eww.scss
    sed -i 's|@base0C|${colorsWithHash.base0C}|g' $out/eww.scss
    sed -i 's|@base0D|${colorsWithHash.base0D}|g' $out/eww.scss
    sed -i 's|@base0E|${colorsWithHash.base0E}|g' $out/eww.scss
    sed -i 's|@base0F|${colorsWithHash.base0F}|g' $out/eww.scss

    # Replace script names with absolute nix store paths in eww.yuck
    sed -i 's|"eww-workspace"|"${eww-workspace-script}/bin/eww-workspace"|g' $out/eww.yuck
    sed -i 's|"eww-mode"|"${eww-mode-script}/bin/eww-mode"|g' $out/eww.yuck
    sed -i 's|"eww-battery"|"${eww-battery-script}/bin/eww-battery"|g' $out/eww.yuck
    sed -i 's|"eww-wifi"|"${eww-wifi-script}/bin/eww-wifi"|g' $out/eww.yuck
    sed -i 's|"eww-wifi-tooltip"|"${eww-wifi-tooltip-script}/bin/eww-wifi-tooltip"|g' $out/eww.yuck
    sed -i 's|"eww-volume"|"${eww-volume-script}/bin/eww-volume"|g' $out/eww.yuck
    sed -i 's|"eww-volume-scroll"|"${eww-volume-scroll-script}/bin/eww-volume-scroll"|g' $out/eww.yuck
    sed -i 's|"eww-disk"|"${eww-disk-script}/bin/eww-disk"|g' $out/eww.yuck
    sed -i 's|"eww-dunst"|"${eww-dunst-script}/bin/eww-dunst"|g' $out/eww.yuck
    sed -i 's|"eww-cpu"|"${eww-cpu-script}/bin/eww-cpu"|g' $out/eww.yuck
    sed -i 's|"eww-memory"|"${eww-memory-script}/bin/eww-memory"|g' $out/eww.yuck
    sed -i 's|"eww-temperature"|"${eww-temperature-script}/bin/eww-temperature"|g' $out/eww.yuck
    sed -i 's|"eww-calendar"|"${eww-calendar-script}/bin/eww-calendar"|g' $out/eww.yuck
    sed -i 's|eww-volume-control|${config.home-manager.window-manager.default.volumeControl}|g' $out/eww.yuck
    sed -i 's|eww-pamixer|${lib.getExe pkgs.pamixer}|g' $out/eww.yuck
    sed -i 's|eww-volume-scroll|${eww-volume-scroll-script}/bin/eww-volume-scroll|g' $out/eww.yuck
  '';
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
        ExecStart = "${lib.getExe pkgs.eww} daemon --no-daemonize";
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
              ]
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
        { command = "${lib.getExe pkgs.eww} open bar"; }
      ];
    };
  };
}
