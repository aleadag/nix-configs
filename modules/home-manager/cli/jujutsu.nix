{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.home-manager.cli.jujutsu;
in
{
  options.home-manager.cli.jujutsu = {
    enable = lib.mkEnableOption "Jujutsu config" // {
      default = config.home-manager.cli.enable;
    };
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      ju = "jjui";
    };

    home.packages = with pkgs; [
      jjui
    ];

    home.file.".config/jjui/config.toml".source = (pkgs.formats.toml { }).generate "jjui-config" {
      ui.auto_refresh_interval = 10; # seconds
    };

    programs.jujutsu = {
      enable = true;
      # XXX: cargo-nextest fails to build on macOS, skip tests until the issue
      # is resolved.
      #
      # cf. https://github.com/NixOS/nixpkgs/issues/456113
      package =
        if pkgs.stdenv.hostPlatform.isDarwin then
          pkgs.jujutsu.override {
            rustPlatform = pkgs.rustPlatform // {
              buildRustPackage = pkgs.rustPlatform.buildRustPackage.override { cargoNextestHook = null; };
            };
          }
        else
          pkgs.jujutsu;
      settings = {
        template-aliases = {
          "format_short_id(id)" = "id.shortest()";
        };
        ui.editor = "nvim";
        user = {
          name = config.meta.fullname;
          inherit (config.meta) email;
        };
      };
    };
  };
}
