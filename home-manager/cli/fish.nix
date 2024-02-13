{ config, flake, lib, pkgs, ... }:
{
  options.home-manager.cli.fish.enable = lib.mkEnableOption "Fish config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.fish.enable {
    programs.fish = {
      enable = true;

      plugins = [
        # tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time=No --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Few icons' --transient=Yes
        { name = "tide"; src = pkgs.fishPlugins.tide.src; }
        { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
        { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
        {
          name = "plugin-proxy";
          src = builtins.getAttr "omf-proxy" flake.inputs;
        }
      ];

      interactiveShellInit =
        ''
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
        '' + lib.optionalString pkgs.stdenv.isDarwin ''
          # Set the soft ulimit to something sensible
          # https://developer.apple.com/forums/thread/735798
          ulimit -Sn 524288
        '';

      functions = {
        nixify =
          ''
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
          ''
            if [ ! -e flake.nix ]
              nix flake new -t github:nix-community/nix-direnv .
            else if [ ! -e .envrc ]
              echo "use flake" > .envrc
            end
            direnv allow
            $EDITOR flake.nix
          '';
        dvt =
          ''
            nix flake init -t "github:the-nix-way/dev-templates#$argv[1]"
            direnv allow
          '';
      };
    };

    xdg.configFile."fish/themes/Catppuccin Frappe.theme".source = "${builtins.getAttr "catppuccin-fish" flake.inputs}/themes/Catppuccin Frappe.theme";

    programs.man.generateCaches = true;
  };
}
