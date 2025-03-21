{
  config,
  lib,
  osConfig,
  ...
}:

let
  inherit (config.home) username;
  cfg = config.home-manager.desktop.firefox;
in
{
  options.home-manager.desktop.firefox = {
    enable = lib.mkEnableOption "Firefox config" // {
      default = config.home-manager.desktop.enable;
    };
    subpixelRender.enable = lib.mkEnableOption {
      default =
        (osConfig.fonts.fontconfig.antialias or false)
        && (osConfig.fonts.fontconfig.subpixel.rgba != "none");
    };
  };

  config = lib.mkIf cfg.enable {
    programs.firefox = {
      enable = true;
      profiles.${username} = {
        settings =
          {
            # disable annoyinh Ctrl+Q shortcut
            "browser.quitShortcut.disabled" = true;
            # don't mess up with paste
            "dom.event.clipboardevents.enabled" = false;
            # enable hw video acceleration, if supported
            "media.ffmpeg.vaapi.enabled" = true;
            # handpicked settings from: https://github.com/arkenfox/user.js/blob/master/user.js
            # ads
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "extensions.htmlaboutaddons.recommendations.enabled" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;
            # telemetry
            "datareporting.policy.dataSubmissionEnable" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "browser.tabs.crashReporting.sendReport" = false;
          }
          // lib.optionalAttrs cfg.subpixelRender.enable {
            # https://pandasauce.org/get-fonts-done/
            "gfx.text.subpixel-position.force-enabled" = true;
            "gfx.webrender.quality.force-subpixel-aa-where-possible" = true;
          };
      };
    };
  };
}
