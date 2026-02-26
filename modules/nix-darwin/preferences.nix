# https://github.com/kclejeune/system/blob/master/modules/darwin/preferences.nix
{ ... }:
{
  system.defaults = {
    # login window settings
    loginwindow = {
      # disable guest account
      GuestEnabled = false;
      # show name instead of username
      SHOWFULLNAME = false;
    };

    # file viewer settings
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXEnableExtensionChangeWarning = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirstOnDesktop = true;
    };

    # trackpad settings
    trackpad = {
      # silent clicking = 0, default = 1
      ActuationStrength = 0;
      # enable tap to click
      Clicking = true;
      # firmness level, 0 = lightest, 2 = heaviest
      FirstClickThreshold = 1;
      # firmness level for force touch
      SecondClickThreshold = 1;
      # don't allow positional right click
      TrackpadRightClick = false;
      # three finger drag for space switching
      # TrackpadThreeFingerDrag = true;
    };

    # firewall settings
    # Use `networking.applicationFirewall.enable' and `networking.applicationFirewall.blockAllIncoming' instead

    spaces = {
      # yabai requires this to be false
      spans-displays = false;
    };

    # dock settings
    dock = {
      # auto show and hide dock
      autohide = true;
      # remove delay for showing dock
      autohide-delay = 0.0;
      # how fast is the dock showing animation
      autohide-time-modifier = 1.0;
      tilesize = 50;
      static-only = false;
      showhidden = false;
      show-recents = false;
      show-process-indicators = true;
      orientation = "bottom";
      mru-spaces = false;
      expose-group-apps = true;
    };

    # global settings are in home-manager/darwin
    # NSGlobalDomain = {};

    CustomUserPreferences = {
      "com.apple.symbolichotkeys" = {
        AppleSymbolicHotKeys = {
          # 64 is 'Show Spotlight search'
          "64" = {
            enabled = true;
            value = {
              parameters = [
                100
                2
                1048576
              ];
              type = "standard";
            };
          };
          # 65 is 'Show Finder search window'
          "65" = {
            enabled = true;
            value = {
              parameters = [
                100
                2
                1572864
              ];
              type = "standard";
            };
          };
        };
      };
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    nonUS.remapTilde = true;
  };
}
