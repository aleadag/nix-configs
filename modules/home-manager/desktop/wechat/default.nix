{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.desktop.wechat;

  # Keep WeChat-specific aliases minimal and rely on system/user fontconfig for defaults.
  wechatFontconfig = pkgs.writeText "wechat-fonts.conf" (builtins.readFile ./wechat-fonts.conf);

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
