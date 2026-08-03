{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  cfg = config.nix-darwin.kanata;
  driverKitExtVersion = "6.2.0";
  kanataConfigFile = ../../../configs/kanata.kbd;
  karabinerDriverKitExtDestPath = "/Applications/.Karabiner-VirtualHIDDevice-Manager.app";
  karabinerFilesPath = "/Library/Application Support/org.pqrs/Karabiner-DriverKit-VirtualHIDDevice";
  karabinerDaemon = "${karabinerFilesPath}/Applications/Karabiner-VirtualHIDDevice-Daemon.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Daemon";
in
{
  options.nix-darwin.kanata = {
    enable = lib.mkEnableOption "kanata launchd service" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    system.activationScripts.applications.text =
      pkgs.lib.mkForce # bash
        ''
          DEST_PATH="${karabinerDriverKitExtDestPath}"
          echo "Checking if Karabiner DriverKit VirtualHIDDevice needs to be installed..."
          echo "Checking destination path: $DEST_PATH"
          echo "Expected version: ${driverKitExtVersion}"
          if [ -d "$DEST_PATH" ]; then
              # purposely keep stderr to see if issues fetching version occur
              CURRENT_VERSION=$(defaults read "$DEST_PATH/Contents/Info" CFBundleVersion | tr -d '\n')
          else
              CURRENT_VERSION="null"
          fi
          if [ ! -d "$DEST_PATH" ] || [ "$CURRENT_VERSION" != "${driverKitExtVersion}" ]; then
              echo "Current version found: $CURRENT_VERSION"
              echo "Destination path does not exist or version mismatch."
              echo "Installing Karabiner DriverKit VirtualHIDDevice..."
              DRIVER_WAS_LOADED=0
              KANATA_WAS_LOADED=0
              if launchctl print "system/org.nixos.karabiner-virtualhiddevice-daemon" >/dev/null; then
                DRIVER_WAS_LOADED=1
                launchctl bootout "system/org.nixos.karabiner-virtualhiddevice-daemon"
              fi
              if launchctl print "system/org.nixos.kanata" >/dev/null; then
                KANATA_WAS_LOADED=1
                launchctl bootout "system/org.nixos.kanata"
              fi
              /usr/sbin/installer -pkg "${pkgs.karabiner-driverkit-virtualhiddevice}/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg" -target /
              MACOS_PATH="$DEST_PATH/Contents/MacOS"
              echo "Removing quarantine attributes..."
              xattr -dr com.apple.quarantine "$DEST_PATH"
              echo activating dext...
              $MACOS_PATH/Karabiner-VirtualHIDDevice-Manager activate
              if [ "$DRIVER_WAS_LOADED" -eq 1 ]; then
                launchctl bootstrap "system" "/Library/LaunchDaemons/org.nixos.karabiner-virtualhiddevice-daemon.plist"
              fi
              if [ "$KANATA_WAS_LOADED" -eq 1 ]; then
                launchctl bootstrap "system" "/Library/LaunchDaemons/org.nixos.kanata.plist"
              fi
              echo "Completed DriverKit service restart"
          fi
          echo "Completed Karabiner DriverKit VirtualHIDDevice activation"
        '';

    launchd.daemons.karabiner-virtualhiddevice-daemon = {
      serviceConfig = {
        ProgramArguments = [ karabinerDaemon ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };

    launchd.daemons.kanata = {
      serviceConfig = {
        ProgramArguments = [
          (getExe pkgs.kanata)
          "--cfg"
          "${kanataConfigFile}"
          "--nodelay"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
        Umask = 63;
        StandardOutPath = "/var/log/kanata.out.log";
        StandardErrorPath = "/var/log/kanata.err.log";
      };
    };
  };
}
