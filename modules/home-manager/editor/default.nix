{ lib, ... }:

{
  imports = [
    ./helix.nix
    ./neovim.nix
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = true;
  };
}
