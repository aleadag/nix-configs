{ config, lib, pkgs, ... }:

let
  # The idea comes from here:
  # https://github.com/berbiche/dotfiles/blob/master/user/nicolas/home.nix
  inherit (lib) mkIf mkDefault optionals;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;

  dummyPackage = pkgs.runCommandLocal "dummy" { } "mkdir $out";
  packageIfLinux = x: if isLinux then x else dummyPackage;

  pkgsUnstable = import <nixpkgs-unstable> { };
in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "awang";
  home.homeDirectory = lib.mkMerge [
    (mkIf isDarwin "/Users/alexander")
    (mkIf (!isDarwin) "/home/awang")
  ];

  home.packages = with pkgs; [
    # Need to test it!
    # pkgs.clash

    # 暂时移除，尚不知道如何设置：allowUnfree = true
    # pkgs.microsoft-edge
    # 在完全切换到hm之前，还是需要ydm
    yadm

    # Nix related
    nix-doc
    nix-index
    nixfmt

    # Formatters
    pkgsUnstable.stylua
  ];

  home.shellAliases = { ll = "ls -l"; };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  xdg = {
    enable = true;
    configFile = { "stylua/stylua.toml".source = ./config/stylua.toml; };
  };

  imports = [ ./nix-nvim ./nix-zsh ./nix-lf ./nix-tmux ];
  # https://github.com/treffynnon/nix-setup/blob/master/home-configs/default.nix
  # 这种方式会报错！暂时绕过去
  # ++ optionals isDarwin [
  #   ./hammerspoon.nix
  # ];

  home.file.".hammerspoon" = {
    enable = mkDefault isDarwin;
    source = ./config/hammerspoon;
    recursive = true;
  };

  # autorandr 1.13 有问题，nixpkgs 尚未更新，故先使用unstable版本
  nixpkgs.overlays =
    [ (self: supper: { autorandr = pkgsUnstable.autorandr; }) ];

  # macOS 上无法编译 man pages
  # https://github.com/NixOS/nixpkgs/issues/196651
  manual.manpages.enable = mkDefault isLinux;

  # Disable for now, as still cannot figure now how to make it work!
  # i18n.inputMethod.enabled = "fcitx5";
  # i18n.inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ libpinyin cloudpinyin ];
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
        shell = {
          program = "${pkgs.zsh}/bin/zsh";
          args = [ "-l" "-c" "source /etc/zshrc && tmux attach || tmux" ];
        };
        font = let fontname = "JetBrainsMono Nerd Font";
        in {
          normal = {
            family = fontname;
            style = "Bold";
          };
          bold = {
            family = fontname;
            style = "Bold";
          };
          italic = {
            family = fontname;
            style = "Light";
          };
          size = 12;
        };
        # Colors (Solarized Dark)
        colors = {
          # default colors
          primary = {
            background = "#002b36"; # base03
            foreground = "#839496"; # base0
          };

          cursor = {
            text = "#002b36";
            cursor = "#839496";
          };

          normal = {
            black = "#073642"; # base02
            red = "#dc322f"; # red
            green = "#859900"; # green
            yellow = "#b58900"; # yellow
            blue = "#268bd2"; # blue
            magenta = "#d33682"; # magenta
            cyan = "#2aa198"; # cyan
            white = "#eee8d5"; # base2;
          };

          bright = {
            black = "#586e75"; # base01
            red = "#cb4b16"; # orange
            green = "#586e75"; # base01
            yellow = "#657b83"; # base00
            blue = "#839496"; # base0
            magenta = "#6c71c4"; # violet
            cyan = "#93a1a1"; # base1
            white = "#fdf6e3"; # base3
          };
        };
      };
    };

    autorandr = {
      enable = mkDefault isLinux;
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

    bat = {
      enable = true;
      # This should pick up the correct colors for the generated theme. Otherwise
      # it is possible to generate a custom bat theme to ~/.config/bat/config
      config = { theme = "base16"; };
    };
    dircolors = {
      enable = true;
      enableZshIntegration = true;
    };
    # Use direnv to manage development environments
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      # optional for nix flakes support in home-manager 21.11, not required in home-manager unstable or 22.05
      # nix-direnv.enableFlakes = true;
    };

    fzf = { enable = true; };

    gh = {
      enable = true;
      settings = {
        editor = "vi";
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };

    git = {
      enable = true;
      userName = "Alexander Wang";
      userEmail = "alexander@tiwater.com";
      aliases = {
        hist =
          "log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short";
      };
      delta.enable = true;
      delta.options.syntax-theme = "gruvbox-dark";
      lfs.enable = true;
      lfs.skipSmudge = true;
      # extraConfig = {
      #   http = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
      #   https = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
      # };
    };

    htop.enable = true;

    jq.enable = true;

    newsboat = {
      enable = true;
      urls = [
        {
          url = "https://rsshub.app/cls/telegraph";
          tags = [ "财经" ];
        }
        {
          url = "https://hnrss.org/newest?points=100";
          tags = [ "技术" ];
        }
        {
          url = "http://feeds.bbci.co.uk/news/world/rss.xml";
          tags = [ "新闻" ];
        }
        {
          url = "https://news.mingpao.com/rss/pns/s00001.xml";
          tags = [ "新闻" ];
        }
        {
          url = "http://www.zhihu.com/rss";
          tags = [ "视野" ];
        }
        {
          url = "http://www.matrix67.com/blog/feed";
          tags = [ "视野" ];
        }
        { url = "https://www.williamlong.info/rss.xml"; }
        { url = "https://feeds.appinn.com/appinns/"; }
        { url = "https://feeds.bbci.co.uk/zhongwen/simp/rss.xml"; }
      ];
      extraConfig = ''
        bookmark-cmd instapaper
        bookmark-autopilot yes
        bind-key i bookmark
      '';
    };

    # starship = {
    #   enable = true;

    #   settings = {
    #     character = {
    #       success_symbol = "[λ](bold green)";
    #       error_symbol = "[λ](bold red)";
    #       vicmd_symbol = "[λ](bold yellow)";
    #     };
    #   };
    # };
  };

  services = { clipmenu.enable = mkDefault isLinux; };
}
