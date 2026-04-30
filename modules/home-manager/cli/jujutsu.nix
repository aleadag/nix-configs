{
  config,
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
    programs = {
      jujutsu = {
        enable = true;
        settings = {
          template-aliases = {
            "format_short_id(id)" = "id.shortest()";
          };
          ui = {
            editor = "nvim";
            paginate = "never";
          };
          user = {
            name = config.meta.fullname;
            inherit (config.meta) email;
          };
        };
      };

      jjui = {
        enable = true;
        settings = {
          ui.auto_refresh_interval = 10; # seconds
        };
      };
    };

    home.shellAliases.ju = "jjui";
  };
}
