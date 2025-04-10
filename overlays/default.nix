{ flake }:
final: prev:

let
  inherit (flake) outputs inputs;
in
outputs.lib.recursiveMergeAttrs [
  (inputs.nixgl.overlays.default final prev)
  {
    # namespaces
    libEx = flake.outputs.lib;

    # custom packages
    arandr = prev.arandr.overrideAttrs (_: {
      src = flake.inputs.arandr;
    });

    change-res = prev.callPackage ../packages/change-res { };

    inherit (flake.inputs.home-manager.packages.${prev.system}) home-manager;

    open-browser = prev.callPackage ../packages/open-browser { };

    kitty-scrollback-nvim = prev.vimUtils.buildVimPlugin rec {
      pname = "kitty-scrollback.nvim";
      version = "6.2.2";

      src = prev.fetchFromGitHub {
        owner = "mikesmithgh";
        repo = "kitty-scrollback.nvim";
        rev = "v${version}";
        hash = "sha256-0OPNHWR/qCbMKDQE6Pbt0Ew9QCm2ZSeZq4s9OL2rj04=";
      };
    };

    neovim-standalone =
      let
        hostname = "neovim-standalone";
        hm =
          (outputs.lib.mkHomeConfig {
            inherit hostname;
            inherit (prev) system;
            configuration = {
              home-manager = {
                dev.nix.enable = true;
                editor.neovim = {
                  icons.enable = false;
                  lsp.enable = true;
                  treeSitter.enable = true;
                };
              };
            };
          }).homeConfigurations.${hostname};
      in
      hm.config.programs.neovim.finalPackage.override {
        luaRcContent = hm.config.xdg.configFile."nvim/init.lua".text;
        wrapRc = true;
      };

    nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

    nix-whereis = prev.callPackage ../packages/nix-whereis { };

    nix-proxy = prev.callPackage ../packages/nix-proxy { };

    run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };
  }
]
