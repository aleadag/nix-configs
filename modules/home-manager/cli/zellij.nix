{
  config,
  lib,
  ...
}:

{
  options.home-manager.cli.zellij.enable = lib.mkEnableOption "Zellij config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.zellij.enable {
    programs.zellij = {
      enable = true;
      settings = {
        default_mode = "normal";
        default_shell = lib.mkIf config.programs.zsh.enable (lib.getExe config.programs.zsh.package);
        pane_frames = true;
        ui = {
          pane_frames = {
            rounded_corners = true;
          };
        };
        simplified_ui = false;
        copy_on_select = true;
        show_startup_tips = false;
        show_release_notes = false;
      };
    };

    home.shellAliases = {
      zj = "zellij";
    };
  };
}
