{ lib, ... }:

{
  imports = [
    ./helix.nix
    ./neovim.nix
    ./vscode
  ];

  options.home-manager.editor.enable = lib.mkEnableOption "editor config" // {
    default = true;
  };
}
