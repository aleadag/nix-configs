{ config, lib, pkgs, ... }:

{
  imports = [ ./trampoline-apps.nix ];

  options.home-manager.darwin.enable = lib.mkEnableOption "Darwin (macOS) config" // {
    default = pkgs.stdenv.isDarwin;
  };

  config = lib.mkIf config.home-manager.darwin.enable {
    home-manager = {
      desktop = {
        twenty-twenty-twenty.enable = true;
        wezterm = {
          enable = pkgs.stdenv.isAarch64; # broken in x86_64-darwin
          fullscreenOnStartup = false;
          fontSize = 14.0;
          opacity = 1.0;
        };
      };
    };

    home.file.".hammerspoon" = {
      source = ./config/hammerspoon;
      recursive = true;
    };

    targets.darwin.defaults = {
      # Disable all automatic substitution
      NSGlobalDomain = {
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      # Do not write .DS_Store files outside macOS
      com.apple.desktopservices = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Disable mouse acceleration
      com.apple.mouse.scalling = -1;
      # com.apple.trackpad.scalling = -1;
    };
  };
}
