{
  config,
  lib,
  ...
}:

{
  options.home-manager.cli.btop.enable = lib.mkEnableOption "btop config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.btop.enable {
    programs.btop = {
      enable = true;
      settings = {
        vim_keys = true;
      };
    };
  };
}
