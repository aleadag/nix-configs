{ lib, ... }:

{
  imports = [
    ./neovim
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = true;
  };
}
