{ config, flake, pkgs, lib, libEx, ... }:

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
    ./starship.nix
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
            src = flake.inputs.catppuccin-bat;
            file = "/themes/Catppuccin ${libEx.capitalizeString config.home-manager.desktop.theme.flavor}.tmTheme";
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
        # fzf.fish is incompatible with other fzf plugins for fish
        # https://github.com/PatrickF1/fzf.fish/wiki/Uninstalling-other-fzf-plugins
        enableFishIntegration = false;
        # fileWidgetOptions = [ "--preview 'head {}'" ];
        # historyWidgetOptions = [ "--sort" ];
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
      # https://unix.stackexchange.com/questions/335648/why-does-the-reset-command-include-a-delay
      reset = "${lib.getExe' pkgs.ncurses "tput"} reset";
    };
  };
}
