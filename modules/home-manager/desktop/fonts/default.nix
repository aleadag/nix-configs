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
  serif = if defaultFonts.serif != [ ] then lib.head defaultFonts.serif else "serif";
  monospace = if defaultFonts.monospace != [ ] then lib.head defaultFonts.monospace else "monospace";
  cjkEnabled = config ? stylix.fonts.cjk && config.stylix.fonts.cjk.enable;
  cjk = if cjkEnabled then config.stylix.fonts.cjk else null;
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
      antialiasing = lib.mkDefault true;
      hinting = lib.mkDefault "slight";
      subpixelRendering = lib.mkDefault "rgb";
      defaultFonts = lib.mkIf cjkEnabled {
        monospace = lib.mkAfter [ cjk.monospace.name ];
        sansSerif = lib.mkAfter [ cjk.sansSerif.name ];
        serif = lib.mkAfter [ cjk.serif.name ];
      };
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
              ${lib.optionalString cjkEnabled ''
                <match target="pattern">
                  <test name="family" qual="any"><string>Noto Sans SC</string></test>
                  <edit name="family" mode="prepend" binding="strong">
                    <string>${cjk.sansSerif.name}</string>
                  </edit>
                </match>
                <match target="pattern">
                  <test name="family" qual="any"><string>Noto Serif SC</string></test>
                  <edit name="family" mode="prepend" binding="strong">
                    <string>${cjk.serif.name}</string>
                  </edit>
                </match>
                <alias>
                  <family>${sansSerif}</family>
                  <prefer>
                    <family>${sansSerif}</family>
                    <family>${cjk.sansSerif.name}</family>
                  </prefer>
                </alias>
                <alias>
                  <family>${serif}</family>
                  <prefer>
                    <family>${serif}</family>
                    <family>${cjk.serif.name}</family>
                  </prefer>
                </alias>
                <alias>
                  <family>${monospace}</family>
                  <prefer>
                    <family>${monospace}</family>
                    <family>${cjk.monospace.name}</family>
                  </prefer>
                </alias>
              ''}
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
          <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
          <include ignore_missing="yes">${config.home.profileDirectory}/etc/fonts/fonts.conf</include>
          <include ignore_missing="yes">${config.home.profileDirectory}/etc/fonts/conf.d</include>
          <include ignore_missing="yes">conf.d</include>
        </fontconfig>
      '';
    };
  };
}
