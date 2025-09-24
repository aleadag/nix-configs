{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.desktop.firefox;
in
{
  options.home-manager.desktop.firefox = {
    enable = lib.mkEnableOption "Firefox config" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
    subpixelRender.enable = lib.mkEnableOption "Subpixel render" // {
      default =
        (osConfig.fonts.fontconfig.antialias or false)
        && (osConfig.fonts.fontconfig.subpixel.rgba != "none");
    };
    proxy.enable = lib.mkEnableOption "Enable proxy" // {
      default = config.home-manager.mihomo.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tridactyl-native ];

    programs.firefox = {
      enable = true;
      # in darwin, firefox is installed by homebrew
      package = lib.mkIf pkgs.stdenv.isDarwin null;
      profiles.default = {
        settings =
          let
            extensions = {
              "extensions.htmlaboutaddons.recommendations.enabled" = false;
              "extensions.update.autoUpdateDefault" = false;
              "extensions.update.enabled" = false;
            };
          in
          {
            # don't mess up with paste
            "dom.event.clipboardevents.enabled" = false;
            # enable hw video acceleration, if supported
            "media.ffmpeg.vaapi.enabled" = true;
            # handpicked settings from: https://github.com/arkenfox/user.js/blob/master/user.js
            # ads
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;

            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
            "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
            "browser.newtabpage.activity-stream.default.sites" = "";
            # disable annoyinh Ctrl+Q shortcut
            "browser.quitShortcut.disabled" = true;
            "browser.tabs.crashReporting.sendReport" = false;
            "browser.urlbar.suggest.quicksuggest.sponsored" = false;

            # telemetry
            "datareporting.policy.dataSubmissionEnable" = false;
            "datareporting.healthreport.uploadEnabled" = false;
          }
          // lib.optionalAttrs cfg.subpixelRender.enable {
            # https://pandasauce.org/get-fonts-done/
            "gfx.text.subpixel-position.force-enabled" = true;
            "gfx.webrender.quality.force-subpixel-aa-where-possible" = true;
          }
          // lib.optionalAttrs cfg.proxy.enable (
            let
              host = "localhost";
              port = 7890;
            in
            {
              "network.proxy.http" = host;
              "network.proxy.http_port" = port;
              "network.proxy.share_proxy_settings" = true;
              "network.proxy.socks" = host;
              "network.proxy.socks_port" = port;
              "network.proxy.ssl" = host;
              "network.proxy.ssl_port" = port;
              "network.proxy.type" = 1;
            }
          )
          // extensions;

        extensions = {
          force = true;
          packages = with pkgs.nur.repos.rycee.firefox-addons; [
            tridactyl
            sponsorblock
            ublock-origin
            ublacklist
            metamask
          ];
        };
      };
    };
  };
}
