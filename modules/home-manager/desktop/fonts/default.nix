{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home-manager.desktop.fonts;
  inherit (pkgs.stdenv.hostPlatform) isLinux;

  defaultFonts = config.fonts.fontconfig.defaultFonts;
  sansSerif = if defaultFonts.sansSerif != [ ] then lib.head defaultFonts.sansSerif else "sans-serif";
  monospace = if defaultFonts.monospace != [ ] then lib.head defaultFonts.monospace else "monospace";
  serif = if defaultFonts.serif != [ ] then lib.head defaultFonts.serif else "serif";
in
{
  options.home-manager.desktop.fonts = {
    enable = lib.mkEnableOption "font config" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.fontconfig = {
      enable = true;
      configFile = lib.mkIf isLinux {
        "49-generic-aliases" = {
          enable = true;
          priority = 49;
          text = ''
            <?xml version="1.0"?>
            <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
            <fontconfig>
              <description>Alias generic UI font families</description>
              <match target="pattern">
                <test name="family" qual="any"><string>system-ui</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>ui-sans-serif</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Sans</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>sans</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Cantarell</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Noto Sans</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Noto Sans SC</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${sansSerif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>mono</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${monospace}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>ui-monospace</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${monospace}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Noto Serif</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${serif}</string>
                </edit>
              </match>
              <match target="pattern">
                <test name="family" qual="any"><string>Noto Serif SC</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>${serif}</string>
                </edit>
              </match>
            </fontconfig>
          '';
        };
      };
    };

    home = lib.mkIf isLinux {
      packages = [
        pkgs.fontconfig
        pkgs.fontconfig.out
      ];
      sessionVariables = {
        FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
      };
    };

    systemd.user.sessionVariables = lib.mkIf isLinux {
      FONTCONFIG_FILE = "${config.xdg.configHome}/fontconfig/fonts.conf";
    };

    xdg.configFile = lib.mkIf isLinux {
      "fontconfig/fonts.conf".text = ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <cachedir prefix="xdg">fontconfig</cachedir>
          <include ignore_missing="yes">${config.home.profileDirectory}/etc/fonts/fonts.conf</include>
          <include ignore_missing="yes">${config.home.profileDirectory}/etc/fonts/conf.d</include>
          <include ignore_missing="yes">conf.d</include>
        </fontconfig>
      '';
    };
  };
}
