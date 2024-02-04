{ pkgs, ... }:
let
  catppuccin-fish = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "fish";
    rev = "0ce27b518e8ead555dec34dd8be3df5bd75cff8e";
    hash = "sha256-Dc/zdxfzAUM5NX8PxzfljRbYvO9f9syuLO8yBr+R3qg=";
  };
in
{
  programs.fish = {
    enable = true;

    shellAliases = {
      # git
      gs = "${pkgs.git}/bin/git status";

      # bat
      cat = "${pkgs.bat}/bin/bat";
    };

    plugins = [
      # tide configure --auto --style=Rainbow --prompt_colors='True color' --show_time=No --rainbow_prompt_separators=Angled --powerline_prompt_heads=Sharp --powerline_prompt_tails=Flat --powerline_prompt_style='Two lines, character' --prompt_connection=Disconnected --powerline_right_prompt_frame=Yes --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Few icons' --transient=Yes
      { name = "tide"; src = pkgs.fishPlugins.tide.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
      {
        name = "plugin-proxy";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-proxy";
          rev = "f5ba6c770112dddcc526e3685fd563814c1c3414";
          sha256 = "sha256-OJfUbT9h5gQGWP/v6BWiDAwfUjgIrbGLXZzdr6fsCyY=";
        };
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

  xdg.configFile."fish/themes/Catppuccin Frappe.theme".source = "${catppuccin-fish}/themes/Catppuccin Frappe.theme";

  # Better 'ls'
  programs.eza = {
    enable = true;
    enableAliases = true;
  };

  programs.man.generateCaches = true;
}
