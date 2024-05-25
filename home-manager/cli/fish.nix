{ config, flake, lib, libEx, pkgs, ... }:
{
  options.home-manager.cli.fish.enable = lib.mkEnableOption "Fish config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.fish.enable {
    home.packages = with pkgs; [ fd /* required by fzf-fish */ ];
    programs.fish = {
      enable = true;

      plugins = [
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
        { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
        { name = "plugin-proxy"; src = flake.inputs.omf-proxy; }
        { name = "bass"; src = pkgs.fishPlugins.bass.src; }
      ];

      shellInit =
        /* fish */ ''
        # fzf.fish configurations, this HAS to be in shellInit
        # https://github.com/PatrickF1/fzf.fish/issues/305
        set fzf_preview_dir_cmd ${lib.getExe pkgs.eza} --all --color=always
        set fzf_diff_highlighter ${lib.getExe pkgs.delta} --paging=never --width=20
      '';

      interactiveShellInit =
        let
          # https://github.com/catppuccin/fzf
          fzfTheme = {
            latte = /* fish */ ''
              set -Ux FZF_DEFAULT_OPTS "\
              --color=bg+:#ccd0da,bg:#eff1f5,spinner:#dc8a78,hl:#d20f39 \
              --color=fg:#4c4f69,header:#d20f39,info:#8839ef,pointer:#dc8a78 \
              --color=marker:#dc8a78,fg+:#4c4f69,prompt:#8839ef,hl+:#d20f39"
            '';
            frappe = /* fish */ ''
              set -Ux FZF_DEFAULT_OPTS "\
              --color=bg+:#414559,bg:#303446,spinner:#f2d5cf,hl:#e78284 \
              --color=fg:#c6d0f5,header:#e78284,info:#ca9ee6,pointer:#f2d5cf \
              --color=marker:#f2d5cf,fg+:#c6d0f5,prompt:#ca9ee6,hl+:#e78284"
            '';
            macchiato = /* fish */ ''
              set -Ux FZF_DEFAULT_OPTS "\
              --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
              --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
              --color=marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796"
            '';
            mocha = /* fish */ ''
              set -Ux FZF_DEFAULT_OPTS "\
              --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
              --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
              --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
            '';
          };
        in
        ""
        + /* fish */ ''
          # proxy
          set proxy_host 127.0.0.1:7890
          set proxy_auth false
          # brew
          set brewcmd (path filter /opt/homebrew/bin/brew /usr/local/bin/brew)[1]
          and $brewcmd shellenv | source

          # nix
          if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
              source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          end
        '' + lib.optionalString pkgs.stdenv.isDarwin /* fish */ ''
          # Set the soft ulimit to something sensible
          # https://developer.apple.com/forums/thread/735798
          ulimit -Sn 524288
        '' + lib.optionalString config.programs.fzf.enable fzfTheme."${config.home-manager.desktop.theme.flavor}";

      functions = {
        nixify =
          /* fish */ ''
          if [ ! -e ./.envrc ]
             echo "use nix" > .envrc
             direnv allow
          end

          set -l defaultNixTest "\
          { pkgs ? import <nixpkgs> {} }:

          pkgs.mkShell {
            packages = with pkgs; [
            ];
          }"
          if not test -e default.nix
             echo $defaultNixTest > default.nix
          end
        '';
        flakify =
          /* fish */ ''
          if [ ! -e flake.nix ]
             nix flake new -t github:nix-community/nix-direnv .
          else if [ ! -e .envrc ]
             echo "use flake" > .envrc
          end
          direnv allow
          $EDITOR flake.nix
        '';
        dvt =
          /* fish */ ''
          nix flake init -t "github:the-nix-way/dev-templates#$argv[1]"
          direnv allow
        '';
      };
    };

    xdg.configFile."fish/themes/catppuccin.theme".source = "${flake.inputs.catppuccin-fish}/themes/Catppuccin ${libEx.capitalizeString config.home-manager.desktop.theme.flavor}.theme";

    programs.man.generateCaches = true;
  };
}
