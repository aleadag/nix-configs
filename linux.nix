# Linux specific settings
{ pkgs, ... }:
let
  fetch-bing-wp = pkgs.callPackage ./scripts/fetch-bing-wp.nix { };
  xsidle = pkgs.callPackage ./scripts/xsidle.nix { };
in {
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

  home.packages = with pkgs; [ megacmd filezilla ];

  home.sessionVariables = { vblank_mode = 0; };

  home.shellAliases = { kit = "GLFW_IM_MODULE=ibus nixGL kitty"; };

  programs.autorandr = {
    enable = true;
    profiles = {
      "work" = {
        fingerprint = {
          eDP-1 =
            "00ffffffffffff000e6f091300000000001e0104a51d147803fad5a3554e9b260f5054000000010101010101010101010101010101015998b8a0b0d0397030203a0025c310000018000000000000000000000000000000000018000000fe0043534f5454330a202020202020000000fe004d4e443838384841312d310a2000ed";
          DP-1 =
            "00ffffffffffff00410c5809c61e00002b1e0104b54627783b57a5ac504aa527125054bfef00d1c0b30095008180814081c0010101014dd000a0f0703e8030403500b9882100001a000000ff0041553032303433303037383738000000fc0050484c2033323842310a202020000000fd00283c8c8c3c010a202020202020013c020321f14b0103051404131f120211902309070783010000681a00000101283c00a36600a0f0701f8030203500b9882100001a565e00a0a0a0295030203500b9882100001e4d6c80a070703e8030203a00b9882100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000b8";
        };
        config = {
          eDP-1 = { enable = false; };
          DP-1 = {
            enable = true;
            crtc = 1;
            primary = true;
            position = "0x0";
            mode = "3840x2160";
            # gamma = "1.0:0.909:0.833";
            rate = "60.00";
            # rotate = "left";
          };
        };
        # hooks.postswitch = readFile ./work-postswitch.sh;
      };
    };
  };

  services = { clipmenu.enable = true; };

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
