{ config, flake, pkgs, lib, ... }:

let
  cfg = config.home-manager.cli;
  get-ip = pkgs.writeShellScriptBin "get-ip" ''
    ${lib.getExe pkgs.curl} -Ss "https://ifconfig.me"
  '';
  get-ip' = pkgs.writeShellScriptBin "get-ip!" ''
    ${lib.getExe pkgs.curl} -Ss "https://ipapi.co/$(${lib.getExe get-ip})/yaml"
  '';
  remove-symlink = pkgs.writeShellScriptBin "remove-symlink" ''
    [[ -L "$1" ]] && \
      ${lib.getExe' pkgs.coreutils "cp"} --remove-destination \
      "$(${lib.getExe' pkgs.coreutils "readlink"} "$1")" "$1"
  '';
in
{
  imports = [
    ./fish.nix
    ./git.nix
    ./htop.nix
    ./irssi.nix
    ./nnn.nix
    ./ssh.nix
    ./tmux.nix
    ./yazi.nix
    ./zsh.nix
  ];

  options.home-manager.cli = {
    enable = lib.mkEnableOption "CLI config" // { default = true; };
    enableGnu = lib.mkEnableOption "GNU utils config" // {
      default = !(config.targets.genericLinux.enable || pkgs.stdenv.isDarwin);
    };
    enableOuch = lib.mkEnableOption "Ouch config" // {
      default = !pkgs.stdenv.isDarwin;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      get-ip
      get-ip'
      remove-symlink

      _7zz
      aria2
      bc
      bind.dnsutils
      curl
      dialog
      dos2unix
      dua
      each
      file
      hyperfine
      ix
      jq
      less
      lsof
      mediainfo
      page
      procps
      pv
      python3
      ripgrep
      rlwrap
      tealdeer
      tokei
      wget
    ]
    ++ lib.optionals cfg.enableOuch [
      ouch
    ]
    ++ lib.optionals cfg.enableGnu [
      coreutils
      diffutils
      findutils
      gawk
      gcal
      gnugrep
      gnumake
      gnused
      inetutils
      netcat-gnu
    ];

    programs = {
      bat = {
        enable = true;
        themes = {
          catppuccin = {
            src = builtins.getAttr "catppuccin-bat" flake.inputs;
            file = "Catppuccin-${config.home-manager.desktop.theme.flavor}.tmTheme";
          };
        };
        # This should pick up the correct colors for the generated theme. Otherwise
        # it is possible to generate a custom bat theme to ~/.config/bat/config
        config = {
          theme = "catppuccin";
          tabs = "2";
          pager = "less -FR";
        };
        extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
      };
      eza = {
        enable = true;
        enableAliases = true;
        git = true;
      };
      fzf = {
        enable = true;
        fileWidgetOptions = [ "--preview 'head {}'" ];
        historyWidgetOptions = [ "--sort" ];
      };
      zoxide.enable = true;
    };

    home.shellAliases = {
      gs = lib.mkIf cfg.git.enable "${lib.getExe config.programs.git.package} status";
      cat = lib.getExe pkgs.bat;
      # For muscle memory...
      archive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} compress";
      unarchive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} decompress";
      lsarchive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} list";
      cal = lib.mkIf cfg.enableGnu (lib.getExe' pkgs.gcal "gcal");
      ncdu = "${lib.getExe pkgs.dua} interactive";
      sloccount = lib.getExe pkgs.tokei;
    };
  };
}
