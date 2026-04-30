{ inputs, outputs, ... }:
final: prev:

inputs.nur.overlays.default final prev
// inputs.llm-agents.overlays.default final prev
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

    inherit (inputs.gh-gfm-preview.packages.${system}) gh-gfm-preview;
    inherit (inputs.nix-proxy-manager.packages.${system}) nix-proxy-manager;

    # https://github.com/NixOS/nixpkgs/issues/507531
    direnv = prev.direnv.overrideAttrs (_: {
      doCheck = !prev.stdenv.isDarwin;
    });

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
            home.stateVersion = "26.05";
          };
        };
      in
      hm.homeConfigurations.${hostName}.config.home-manager.editor.neovim.standalonePackage;

    nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

    nixos-cleanup = final.nix-cleanup.override { isNixOS = true; };

    darwin-cleanup = final.nix-cleanup.override { isNixDarwin = true; };

    nix-whereis = prev.callPackage ../packages/nix-whereis { };

    run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };

    realise-symlink = prev.writeShellApplication {
      name = "realise-symlink";
      runtimeInputs = with prev; [ coreutils ];
      text = ''
        for file in "$@"; do
          if [[ -L "$file" ]]; then
            if [[ -d "$file" ]]; then
              tmpdir="''${file}.tmp"
              mkdir -p "$tmpdir"
              cp --verbose --recursive --dereference "$file"/* "$tmpdir"
              unlink "$file"
              mv "$tmpdir" "$file"
              chmod --changes --recursive +w "$file"
            else
              cp --verbose --remove-destination "$(readlink "$file")" "$file"
              chmod --changes +w "$file"
            fi
          else
            >&2 echo "Not a symlink: $file"
            exit 1
          fi
        done
      '';
    };

    karabiner-driverkit-virtualhiddevice =
      prev.callPackage ../packages/karabiner-driverkit-virtualhiddevice
        { };
  }
)
