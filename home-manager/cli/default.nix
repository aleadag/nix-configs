{ config, pkgs, lib, ... }:

let
  cfg = config.home-manager.cli;
in
{
  imports = [
    ./git.nix
    ./htop.nix
    ./irssi.nix
    ./nnn.nix
    ./ssh.nix
    ./tmux.nix
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
          Catppuccin-frappe = {
            src = pkgs.fetchFromGitHub
              {
                owner = "catppuccin";
                repo = "bat";
                rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
                sha256 = "6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
              };
            file = "Catppuccin-frappe.tmTheme";
          };
        };
        # This should pick up the correct colors for the generated theme. Otherwise
        # it is possible to generate a custom bat theme to ~/.config/bat/config
        config = {
          theme = "Catppuccin-frappe";
          tabs = "2";
          pager = "less -FR";
        };
        extraPackages = with pkgs.bat-extras; [ batdiff batman batgrep batwatch ];
      };
      zsh.shellAliases = {
        # For muscle memory...
        archive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} compress";
        unarchive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} decompress";
        lsarchive = lib.mkIf cfg.enableOuch "${lib.getExe pkgs.ouch} list";
        cal = lib.mkIf cfg.enableGnu (lib.getExe' pkgs.gcal "gcal");
        ncdu = "${lib.getExe pkgs.dua} interactive";
        sloccount = lib.getExe pkgs.tokei;
      };
    };
  };
}
