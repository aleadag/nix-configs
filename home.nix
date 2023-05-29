{ config, lib, pkgs, ... }:

let
  # The idea comes from here:
  # https://github.com/berbiche/dotfiles/blob/master/user/nicolas/home.nix
  # https://github.com/treffynnon/nix-setup/blob/master/home-configs/default.nix
  inherit (lib) mkIf mkDefault optionals;
  inherit (builtins) currentSystem;
  inherit (lib.systems.elaborate { system = currentSystem; }) isLinux isDarwin;

  secrets = import ./secrets.nix { };
  add-to-instapaper =
    pkgs.callPackage ./scripts/add-to-instapaper.nix { inherit config; };
in {
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "awang";
  home.homeDirectory = lib.mkMerge [
    (mkIf isDarwin "/Users/alexander")
    (mkIf (!isDarwin) "/home/awang")
  ];

  # script-directory
  home.file."sd" = {
    source = ./sd;
    recursive = true;
  };

  home.packages = with pkgs; [
    # Need to test it!
    # pkgs.clash

    # 暂时移除，尚不知道如何设置：allowUnfree = true
    # pkgs.microsoft-edge

    # Nix related
    nix-doc
    nix-index

    # Formatters
    dprint
    nixfmt
    shfmt
    stylua

    git-crypt
    ripgrep # for VIM telescope live grep
    xh
  ];

  home.shellAliases = {
    ls = "ls --color=auto";
    ll = "ls -l --color=auto";
    cat = "bat";
    s = "kitty +kitten ssh";
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = secrets;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  nix = {
    package = pkgs.nix;
    settings = { experimental-features = [ "nix-command" "flakes" ]; };
  };

  xdg = {
    enable = true;
    configFile = { "stylua/stylua.toml".source = ./config/stylua.toml; };
  };

  imports = [ ./nix-nvim ./nix-zsh ./irssi.nix ./httpie.nix ]
    ++ optionals isDarwin [ ./macOS.nix ] ++ optionals isLinux [ ./linux.nix ];

  # Disable for now, as still cannot figure now how to make it work!
  # i18n.inputMethod.enabled = "fcitx5";
  # i18n.inputMethod.fcitx.engines = with pkgs.fcitx-engines; [ libpinyin cloudpinyin ];
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;

    aria2 = {
      enable = true;
      settings = {
        rpc-secret = "nJszuqG+%rs";
        enable-rpc = true;
        # 允许所有来源, web界面跨域权限需要
        rpc-allow-origin-all = true;
        # 允许外部访问，false的话只监听本地端口
        rpc-listen-all = true;
        # 设置代理
        # all-proxy="localhost:7890"
        # 最大同时下载数(任务数), 路由建议值: 3
        max-concurrent-downloads = 5;
        # 断点续传
        continue = true;
        # 同服务器连接数
        max-connection-per-server = 5;
        # 最小文件分片大小, 下载线程数上限取决于能分出多少片, 对于小文件重要
        min-split-size = "10M";
        # 单文件最大线程数, 路由建议值: 5
        split = 10;
        # 下载速度限制
        max-overall-download-limit = 0;
        # 单文件速度限制
        max-download-limit = 0;
        # 上传速度限制
        max-overall-upload-limit = 0;
        # 单文件速度限制
        max-upload-limit = 0;
        # 断开速度过慢的连接
        # lowest-speed-limit=0
        # 文件保存路径, 默认为当前启动位置
        dir = "${config.home.homeDirectory}/Downloads";
      };
    };

    bat = {
      enable = true;
      # This should pick up the correct colors for the generated theme. Otherwise
      # it is possible to generate a custom bat theme to ~/.config/bat/config
      config = {
        theme = "base16";
        tabs = "2";
        pager = "less -FR";
      };
    };

    broot = { enable = true; };

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
        pager = "less -RF";
      };
    };

    git = {
      enable = true;
      userName = "Alexander Wang";
      userEmail = "aleadag@gmail.com";
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

    gpg = { enable = true; };

    htop.enable = true;

    jq.enable = true;

    kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 12;
      };
      theme = "GitHub Dark Dimmed";
      settings = { adjust_column_width = -1; };
    };

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
        bookmark-cmd ${add-to-instapaper}/bin/add-to-instapaper
        bookmark-autopilot yes
        bind-key i bookmark

        # Dark solarized color scheme for newsbeuter
        color background         default   default
        color listnormal         default   default
        color listnormal_unread  default   default
        color listfocus          black     yellow
        color listfocus_unread   black     yellow
        color info               default   black
        color article            default   default

        # highlights
        highlight article "^(Title):.*$" blue default
        highlight article "https?://[^ ]+" red default
        highlight article "\\[image\\ [0-9]+\\]" green default
      '';
    };

    nnn = {
      enable = true;
      bookmarks = {
        c = "~/hacking";
        d = "~/Documents";
        D = "~/Downloads";
        p = "~/Pictures";
        v = "~/Videos";
      };
    };

    # script-directory = {
    #   enable = true;
    # };

    sioyek.enable = true;

    script-directory = {
      enable = true;
      settings = {
        # SD_ROOT = "${config.home.homeDirectory}/.sd";
        SD_EDITOR = "nvim";
        SD_CAT = "bat";
      };
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
}
