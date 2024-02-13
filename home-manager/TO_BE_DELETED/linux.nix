# Linux specific settings
{ pkgs, ... }:
let
  fetch-bing-wp = pkgs.callPackage ./scripts/fetch-bing-wp.nix { };
  xsidle = pkgs.callPackage ./scripts/xsidle.nix { };
in
{
  programs.zsh.profileExtra = ''
    if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
      exec startx
    fi
  '';

  home.file.".xinitrc".text = ''
    systemctl --user import-environment DISPLAY XAUTHORITY

    # Set key press auto-repeat
    xset r rate 300 50
    fcitx5 &
    # dwm status bar
    dwmstatus 2>&1 >/dev/null &

    # Set a random wallpaper
    # feh --bg-fill --randomize ~/Pictures/Wallpapers/*
    $HOME/.fehbg

    # 启用 compositor，这样才能把st的背景变得透明
    picom &

    # 熄屛后需输入密码
    ${xsidle}/bin/xsidle slock &

    exec dwm
  '';

  home.packages = with pkgs; [ megacmd ];
  home.sessionVariables = { vblank_mode = 0; };
  home.shellAliases = { kit = "GLFW_IM_MODULE=ibus nixGL kitty"; };

  services.clipmenu.enable = true;

  systemd.user = {
    services = {
      feh-bing = {
        Unit = {
          Description = "Downloads BING image and sets a wallpaper";
          PartOf = "graphical-session.target";
        };

        Service = { ExecStart = "${fetch-bing-wp}/bin/fetch-bing-wp"; };
      };
    };

    timers = {
      feh-bing = {
        Unit = { Description = "Run feh-bing service repeatly and on boot"; };

        Timer = {
          OnBootSec = "30min";
          OnUnitActiveSec = "3h";
        };
      };
    };
  };
}
