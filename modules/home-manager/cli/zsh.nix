{
  config,
  pkgs,
  lib,
  flake,
  ...
}:

let
  cfg = config.home-manager.cli.zsh;
  realise-symlink = pkgs.writeShellApplication {
    name = "realise-symlink";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      for file in "$@"; do
        if [[ -L "$file" ]]; then
          if [[ -d "$file" ]]; then
            tmpdir="''${file}.tmp"
            mkdir -p "$tmpdir"
            cp --verbose --recursive "$file"/* "$tmpdir"
            unlink "$file"
            mv "$tmpdir" "$file"
            chmod --changes --recursive +w "$file"
          else
            cp --verbose --remove-destination "$(readlink "$file")" "$file"
            chmod --changes +w "$file"
          fi
        else
          >&2 echo "Not a symlink: $file"
          exit 1
        fi
      done
    '';
  };
in
{
  options.home-manager.cli.zsh = {
    enable = lib.mkEnableOption "ZSH config" // {
      default = config.home-manager.cli.enable;
    };
    # Do not forget to set 'Hack Nerd Mono Font' as the terminal font
    icons.enable = lib.mkEnableOption "icons" // {
      default = config.home-manager.desktop.enable || config.home-manager.darwin.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      # disable login banner
      file.".hushlogin".text = "";
      packages =
        with pkgs;
        [
          realise-symlink
        ]
        ++ lib.optionals (!stdenv.isDarwin) [
          (run-bg-alias "open" (lib.getExe' xdg-utils "xdg-open"))
        ];

      sessionPath = [ "$HOME/.local/bin" ];
      sessionSearchVariables.MANPATH = lib.mkAfter [ ":" ];
    };

    programs = {
      dircolors.enable = true;
      fzf = {
        enable = true;
        fileWidgetOptions = [ "--preview 'head {}'" ];
        historyWidgetOptions = [ "--sort" ];
        enableZshIntegration = false;
      };
      zoxide = {
        enable = true;
        enableZshIntegration = false;
      };
      zsh = {
        enable = true;
        autocd = true;
        defaultKeymap = "viins";

        history = {
          append = true;
          expireDuplicatesFirst = true;
          extended = true;
          ignoreDups = true;
          ignoreSpace = true;
          share = true;
        };

        profileExtra = lib.concatStringsSep "\n" (
          lib.filter (x: x != "") [
            (lib.optionalString config.home-manager.crostini.enable # bash
              ''
                # Force truecolor support in Crostini
                export COLORTERM=truecolor
                # https://github.com/nix-community/home-manager/issues/3711
                export LC_CTYPE=C.UTF-8
              ''
            )
            (lib.optionalString pkgs.stdenv.isDarwin # bash
              ''
                # Source nix-daemon profile since macOS updates can remove it from /etc/zshrc
                # https://github.com/NixOS/nix/issues/3616
                if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
                  source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
                fi
                # Set the soft ulimit to something sensible
                # https://developer.apple.com/forums/thread/735798
                ulimit -Sn 524288
              ''
            )
            # bash
            ''
              # Source .profile
              [[ -e ~/.profile ]] && emulate sh -c '. ~/.profile'
            ''
          ]
        );

        initExtraBeforeCompInit = # bash
          ''
            # try to correct the spelling of commands
            setopt correct
            # disable C-S/C-Q
            setopt noflowcontrol
            # disable "no matches found" check
            unsetopt nomatch

            # source contents from ~/.zshrc.d/*.zsh
            for file in "$HOME/.zshrc.d/"*.zsh; do
              [[ -f "$file" ]] && source "$file"
            done
          '';

        initExtra =
          # bash
          ''
            # disable clock
            unset RPROMPT

            # prezto default matching does annoying partial matching
            # e.g.: something-|.json
            zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' 'm:{[:upper:]}={[:lower:]}' 'r:|=* r:|=*'
          '';

        prezto = {
          enable = true;
          editor.keymap = "vi";
          pmodules = [
            "environment"
            "terminal"
            "editor"
            "history-substring-search"
            "directory"
            "spectrum"
            "utility"
            "completion"
            "autosuggestions"
          ];
        };

        plugins = with pkgs; [
          # manually creating integrations since this is faster than calling
          # the program during startup (e.g. `zoxide init zsh`)
          {
            name = "nix-your-shell";
            src = pkgs.runCommand "nix-your-shell" { buildInputs = [ pkgs.nix-your-shell ]; } ''
              mkdir -p $out
              nix-your-shell --absolute zsh > $out/nix-your-shell.plugin.zsh
            '';
          }
          {
            name = "fzf";
            file = "share/fzf/completion.zsh";
            src = config.programs.fzf.package;
          }
          {
            name = "fzf";
            file = "share/fzf/key-bindings.zsh";
            src = config.programs.fzf.package;
          }
          {
            name = "zoxide";
            src = pkgs.runCommand "zoxide-init-zsh" { buildInputs = [ config.programs.zoxide.package ]; } ''
              mkdir -p $out
              zoxide init zsh > $out/zoxide.plugin.zsh
            '';
          }
          {
            name = "zsh-fast-syntax-highlighting";
            file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
            src = zsh-fast-syntax-highlighting;
          }
          {
            name = "zsh-autopair";
            file = "share/zsh/zsh-autopair/autopair.zsh";
            src = zsh-autopair;
          }
          {
            name = "zsh-proxy";
            file = "zsh-proxy.plugin.zsh";
            src = flake.inputs.zsh-proxy;
          }
          {
            name = "forgit";
            file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
            src = zsh-forgit;
          }
        ];

        sessionVariables = {
          # Enable scroll support
          PAGER = "less -R";
          # Reduce time to wait for multi-key sequences
          KEYTIMEOUT = 1;
          # Set right prompt to show time
          RPROMPT = "%F{8}%*";
        };
      };
    };
  };
}
