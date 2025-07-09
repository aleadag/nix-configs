{
  config,
  flake,
  lib,
  pkgs,
  ...
}:
{
  options.home-manager.cli.fish.enable = lib.mkEnableOption "Fish config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.fish.enable {
    home.packages = with pkgs; [
      fd # required by fzf-fish
    ];
    programs.fish = {
      enable = true;

      plugins = [
        {
          name = "fzf-fish";
          inherit (pkgs.fishPlugins.fzf-fish) src;
        }
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        {
          name = "plugin-proxy";
          src = flake.inputs.omf-proxy;
        }
        {
          name = "bass";
          inherit (pkgs.fishPlugins.bass) src;
        }
      ];

      shellInit =
        # fish
        ''
          # fzf.fish configurations, this HAS to be in shellInit
          # https://github.com/PatrickF1/fzf.fish/issues/305
          set fzf_preview_dir_cmd ${lib.getExe pkgs.eza} --all --color=always
          set fzf_diff_highlighter ${lib.getExe pkgs.delta} --paging=never --width=20
        '';

      interactiveShellInit =
        ""
        # fish
        + ''
          # proxy
          set proxy_host 127.0.0.1:7890
          set proxy_auth false

          # nix
          if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
              source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
          end
        ''
        +
          lib.optionalString pkgs.stdenv.isDarwin # fish
            ''
              # Set the soft ulimit to something sensible
              # https://developer.apple.com/forums/thread/735798
              ulimit -Sn 524288
            '';
    };

    xdg.configFile."fish/completions/just.fish".text = ''
      complete -c just -a (just --summary)
    '';

    programs.man.generateCaches = true;
  };
}
