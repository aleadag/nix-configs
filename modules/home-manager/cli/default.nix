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
in
{
  imports = [
    ./btop.nix
    ./bulletty.nix
    ./git.nix
    ./gnu.nix
    ./htop.nix
    ./irssi.nix
    ./jujutsu.nix
    ./pass.nix
    ./ssh
    ./starship.nix
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
    home = {
      packages =
        with pkgs;
        [
          dvt
          get-ip
          get-ip'

          _7zz
          bc
          bind.dnsutils
          curl
          dialog
          dos2unix
          dua
          each
          ffmpeg
          file
          hyperfine
          imagemagick
          lsof
          mediainfo
          nur.repos.mio.breathe-cli
          ouch
          page
          parallel
          pv
          python3
          rlwrap
          tealdeer
          tree
          viu
          vitaly
          tokei
          watch
          wget
        ]
        ++ (lib.optionals stdenv.isLinux [
          bluetui
          rustnet
        ]);

      sessionVariables = {
        # https://felipec.wordpress.com/2021/06/05/adventures-with-man-color/
        MANPAGER = "less --use-color -Dd+r -Du+b";
      };
      sessionPath = [ "$HOME/.local/bin" ];

      shellAliases = {
        l = "${lib.getExe' pkgs.coreutils "ls"} -alh --color=auto";
        ls = "${lib.getExe' pkgs.coreutils "ls"} --color=auto";
        ll = "${lib.getExe' pkgs.coreutils "ls"} -l --color=auto";
        gs = lib.mkIf cfg.git.enable "${lib.getExe config.programs.git.package} status";
        # For muscle memory...
        archive = "${lib.getExe pkgs.ouch} compress";
        unarchive = "${lib.getExe pkgs.ouch} decompress";
        lsarchive = "${lib.getExe pkgs.ouch} list";
        ncdu = "${lib.getExe pkgs.dua} interactive";
        sloccount = lib.getExe pkgs.tokei;
        reset = lib.getExe' pkgs.ncurses "reset";
        ns = lib.mkIf config.programs.fzf.enable "${lib.getExe pkgs.nix-search-tv} print | ${lib.getExe pkgs.fzf} --preview '${lib.getExe pkgs.nix-search-tv} preview {}' --scheme history";
      };
    };

    programs = {
      aria2.enable = true;
      fd.enable = true;
      jq.enable = true;
      less = {
        enable = true;
        options = {
          chop-long-lines = true;
          hilite-search = true;
          hilite-unread = true;
          ignore-case = true;
          LONG-PROMPT = true;
          mouse = true;
          no-init = true;
          RAW-CONTROL-CHARS = true;
          wheel-lines = 3;
          window = 4;
        };
      };
      man =
        let
          mandocWrapped =
            with pkgs;
            symlinkJoin {
              name = "${mandoc.name}-wrapped";
              paths = [ mandoc ];
              nativeBuildInputs = [ makeWrapper ];
              postBuild = ''
                rm -f "$out/bin/man"
                makeWrapper ${lib.getExe mandoc} "$out/bin/man" \
                  --run 'if [ -t 1 ]; then cols="$(${lib.getExe' ncurses "tput"} cols 2>/dev/null || true)"; if [ -n "$cols" ]; then set -- -O "width=$cols" "$@"; fi; fi'
              '';
            };
        in
        {
          generateCaches = true;
          package = mandocWrapped;
          man-db.enable = false;
          mandoc.enable = true;
        };
      nix-your-shell.enable = true;
      readline = {
        enable = true;
        variables = {
          keymap = "vi";
          editing-mode = "vi";
          show-mode-in-prompt = true;
        };
      };
      ripgrep.enable = true;
    };
  };
}
