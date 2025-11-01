{ inputs, outputs, ... }:
final: prev:

inputs.nur.overlays.default final prev
// (
  let
    inherit (prev.stdenv.hostPlatform) system;
  in
  {
    # Adds pkgs.stable
    stable = import inputs.nixpkgs-stable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };

    # namespaces
    libEx = outputs.lib;

    # custom packages
    arandr = prev.arandr.overrideAttrs (_: {
      src = inputs.arandr;
    });

    inherit (inputs.gh-gfm-preview.packages.${system}) gh-gfm-preview;
    inherit (inputs.nix-proxy-manager.packages.${system}) nix-proxy-manager;

    neovim-standalone =
      let
        hostName = "neovim-standalone";
        hm = outputs.lib.mkHomeConfig {
          inherit hostName system;
          configuration = {
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
)
