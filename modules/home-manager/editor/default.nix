{ lib, ... }:

{
  imports = [
    ./helix.nix
    ./neovim.nix
    ./code-cursor.nix
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = true;
  };
}
