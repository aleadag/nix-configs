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

  aliasRules = [
    {
      target = sansSerif;
      families = [
        "system-ui"
        "ui-sans-serif"
        "Sans"
        "sans"
        "Cantarell"
      ];
    }
    {
      target = serif;
      families = [
        "ui-serif"
      ];
    }
    {
      target = monospace;
      families = [
        "mono"
        "ui-monospace"
      ];
    }
  ]
  ++ lib.optionals cjkEnabled [
    {
      target = cjk.sansSerif.name;
      families = [ "Noto Sans SC" ];
    }
    {
      target = cjk.serif.name;
      families = [ "Noto Serif SC" ];
    }
  ];

  mkAliases = lib.concatMapStrings (
    { target, families }:
    lib.concatMapStrings (family: ''
      <match target="pattern">
        <test name="family" qual="any"><string>${family}</string></test>
        <edit name="family" mode="prepend" binding="strong">
          <string>${target}</string>
        </edit>
      </match>
    '') families
  );

  preferFallbacks = lib.optionals cjkEnabled [
    {
      family = sansSerif;
      fallback = cjk.sansSerif.name;
    }
    {
      family = serif;
      fallback = cjk.serif.name;
    }
    {
      family = monospace;
      fallback = cjk.monospace.name;
    }
  ];

  mkPreferFallbacks = lib.concatMapStrings (
    { family, fallback }: ''
      <alias>
        <family>${family}</family>
        <prefer>
          <family>${family}</family>
          <family>${fallback}</family>
        </prefer>
      </alias>
    ''
  );
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
              ${mkAliases aliasRules}
              ${mkPreferFallbacks preferFallbacks}
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
