{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.cli;
  dvt = pkgs.writeShellScriptBin "dvt" ''
    nix flake init -t "github:the-nix-way/dev-templates#$1"
    direnv allow
  '';
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
    ./btop.nix
    ./git.nix
    ./htop.nix
    ./irssi.nix
    ./jujutsu.nix
    ./pass.nix
    ./ssh
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
    ./zellij.nix
    ./zsh.nix
  ];

  options.home-manager.cli = {
    enable = lib.mkEnableOption "CLI config" // {
      default = true;
    };
    # Do not forget to set 'Hack Nerd Mono Font' as the terminal font
    icons.enable = lib.mkEnableOption "terminal icons" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dvt
      get-ip
      get-ip'
      remove-symlink

      _7zz
      bc
      bind.dnsutils
      clock-rs
      curl
      dialog
      dos2unix
      dua
      each
      file
      ffmpeg
      hyperfine
      imagemagick
      lsof
      mediainfo
      ouch
      page
      pv
      python3
      rlwrap
      tealdeer
      tokei
      uutils-coreutils-noprefix
      websocat
      wget
      railway

      # modern unix: https://github.com/ibraheemdev/modern-unix
      duf
      dust
    ];

    programs = {
      aria2.enable = true;
      jq.enable = true;
      less.enable = true;
      ripgrep.enable = true;

      bat = {
        enable = true;
        # This should pick up the correct colors for the generated theme. Otherwise
        # it is possible to generate a custom bat theme to ~/.config/bat/config
        config = {
          tabs = "2";
          pager = "less -FR";
        };
        # remove batdiff as it failed to build
        # https://github.com/NixOS/nixpkgs/issues/336312
        extraPackages = with pkgs.bat-extras; [
          batman
          batgrep
          batwatch
        ];
      };
      eza = {
        enable = true;
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
      nix-your-shell.enable = true;
      zoxide.enable = true;
    };

    home.sessionVariables = {
      # https://github.com/sharkdp/bat/issues/2578
      LESSUTFCHARDEF = "E000-F8FF:p,F0000-FFFFD:p,100000-10FFFD:p";
    };

    home.shellAliases = {
      gs = lib.mkIf cfg.git.enable "${lib.getExe config.programs.git.package} status";
      cat = lib.getExe pkgs.bat;
      # For muscle memory...
      archive = "${lib.getExe pkgs.ouch} compress";
      unarchive = "${lib.getExe pkgs.ouch} decompress";
      lsarchive = "${lib.getExe pkgs.ouch} list";
      cal = lib.getExe' pkgs.gcal "gcal";
      ncdu = "${lib.getExe pkgs.dua} interactive";
      sloccount = lib.getExe pkgs.tokei;
      # https://unix.stackexchange.com/questions/335648/why-does-the-reset-command-include-a-delay
      reset = "${lib.getExe' pkgs.ncurses "tput"} reset";
    };
  };
}
