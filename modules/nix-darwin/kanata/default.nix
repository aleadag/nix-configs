{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin.kanata;
  driverKitExtVersion = "6.2.0";
  kanataConfigFile = ../../../configs/kanata.kbd;
  kanataBin = "/run/current-system/sw/bin/kanata";
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
    environment.systemPackages = [ pkgs.kanata ];

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

    system.activationScripts.postActivation.text = ''
      echo "Configuring Kanata TCC permissions..."
      KANATA_REAL_BIN="$(readlink -f "${pkgs.kanata}/bin/kanata")"
      if [ -f "$KANATA_REAL_BIN" ]; then
        CDHASH=$(/usr/bin/codesign -dvvv "$KANATA_REAL_BIN" 2>&1 | /usr/bin/awk -F= '/^CDHash=/{print $2}')
        TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"
        if [ -n "$CDHASH" ] && [ -f "$TCC_DB" ]; then
          echo "Registering Kanata binary $KANATA_REAL_BIN ($CDHASH) in TCC database..."
          /usr/bin/sqlite3 "$TCC_DB" "
            DELETE FROM access WHERE client LIKE '%/bin/kanata';
            INSERT OR REPLACE INTO access (
              service, client, client_type, auth_value, auth_reason, auth_version,
              csreq, indirect_object_identifier, flags, last_modified
            ) VALUES
              ('kTCCServiceListenEvent', '$KANATA_REAL_BIN', 1, 2, 4, 1, X'FADE0C0000000028000000010000000800000014' || unhex('$CDHASH'), 'UNUSED', 0, CAST(strftime('%s', 'now') AS INTEGER)),
              ('kTCCServiceAccessibility', '$KANATA_REAL_BIN', 1, 2, 4, 1, X'FADE0C0000000028000000010000000800000014' || unhex('$CDHASH'), 'UNUSED', 0, CAST(strftime('%s', 'now') AS INTEGER));
          "
          echo "Reloading tccd to apply updated TCC permissions..."
          /usr/bin/pkill -9 -f "tccd" || true
          if /bin/launchctl print "system/org.nixos.kanata" >/dev/null 2>&1; then
            echo "Restarting org.nixos.kanata..."
            /bin/launchctl kickstart -k "system/org.nixos.kanata" || true
          fi
        else
          echo "Warning: Could not extract CDHash for Kanata or TCC.db not found." >&2
        fi
      fi
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
          kanataBin
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
