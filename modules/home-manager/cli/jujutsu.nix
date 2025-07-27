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
    home.packages = with pkgs; [
      jjui
      jj-fzf
    ];

    home.file.".config/jjui/config.toml".source = (pkgs.formats.toml { }).generate "jjui-config" {
      ui.auto_refresh_interval = 10; # seconds
    };

    programs.jujutsu = {
      enable = true;
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
