{ inputs, outputs, ... }:
final: prev:

inputs.nur.overlays.default final prev
// {
  # namespaces
  libEx = outputs.lib;

  # custom packages
  arandr = prev.arandr.overrideAttrs (_: {
    src = inputs.arandr;
  });

  inherit (inputs.home-manager.packages.${prev.system}) home-manager;

  inherit (inputs.gh-gfm-preview.packages.${prev.system}) gh-gfm-preview;

  inherit (inputs.nix-proxy-manager.packages.${prev.system}) nix-proxy-manager;

  open-browser = prev.callPackage ../packages/open-browser { };

  neovim-standalone =
    let
      hostName = "neovim-standalone";
      hm = outputs.lib.mkHomeConfig {
        inherit hostName;
        inherit (prev) system;
        configuration = {
          catppuccin = {
            # to make flake check happy
            eza.enable = false;
            firefox.enable = false;
            lazygit.enable = false;
            starship.enable = false;
          };
          home-manager = {
            cli.icons.enable = false;
            dev.nix.enable = true;
            editor.neovim = {
              lsp.enable = true;
              treeSitter.enable = true;
            };
          };
          home.stateVersion = "25.11";
        };
      };
    in
    hm.homeConfigurations.${hostName}.config.home-manager.editor.neovim.standalonePackage;

  nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

  nixos-cleanup = final.nix-cleanup.override { isNixOS = true; };

  darwin-cleanup = final.nix-cleanup.override { isNixDarwin = true; };

  nix-whereis = prev.callPackage ../packages/nix-whereis { };

  run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };

  karabiner-driverkit-virtualhiddevice =
    prev.callPackage ../packages/karabiner-driverkit-virtualhiddevice
      { };
}
