{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.wechat;

  # Create a fontconfig file specifically for wechat-uos
  wechatFontconfig = pkgs.writeText "wechat-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <!-- Include system configuration -->
      <include ignore_missing="yes">/etc/fonts/fonts.conf</include>

      <!-- Load font directories -->
      <dir>~/.fonts</dir>
      <dir>~/.local/share/fonts</dir>
      <dir>/usr/share/fonts</dir>
      <dir>${config.home.homeDirectory}/.nix-profile/share/fonts</dir>

      <cachedir>~/.cache/fontconfig</cachedir>

      <!-- Map "Noto Sans SC" to "Noto Sans CJK SC" -->
      <match target="pattern">
        <test qual="any" name="family">
          <string>Noto Sans SC</string>
        </test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Noto Sans CJK SC</string>
        </edit>
      </match>

      <!-- Map "Noto Serif SC" to "Noto Serif CJK SC" -->
      <match target="pattern">
        <test qual="any" name="family">
          <string>Noto Serif SC</string>
        </test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Noto Serif CJK SC</string>
        </edit>
      </match>

      <!-- Prefer CJK fonts for Chinese characters -->
      <match target="pattern">
        <test name="lang" compare="contains">
          <string>zh</string>
        </test>
        <test name="family">
          <string>sans-serif</string>
        </test>
        <edit name="family" mode="prepend" binding="strong">
          <string>Noto Sans CJK SC</string>
        </edit>
      </match>
    </fontconfig>
  '';

  # Wrapper for wechat-uos with proper font configuration
  wechat-uos-wrapped = pkgs.symlinkJoin {
    name = "wechat-uos-wrapped";
    paths = [ pkgs.wechat-uos ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/wechat-uos \
        --set FONTCONFIG_FILE ${wechatFontconfig}

      # Update desktop file to use wrapped binary
      if [ -e $out/share/applications/com.tencent.wechat.desktop ]; then
        rm $out/share/applications/com.tencent.wechat.desktop
        substitute ${pkgs.wechat-uos}/share/applications/com.tencent.wechat.desktop \
          $out/share/applications/com.tencent.wechat.desktop \
          --replace-fail '${pkgs.wechat-uos}/bin/wechat-uos' "$out/bin/wechat-uos"
      fi
    '';
  };
in
{
  options.home-manager.desktop.wechat = {
    enable = lib.mkEnableOption "wechat-uos with font fixes" // {
      default = config.home-manager.desktop.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ wechat-uos-wrapped ];
  };
}
