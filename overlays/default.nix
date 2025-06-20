{ inputs, outputs }:
final: prev:

{
  # namespaces
  libEx = outputs.lib;

  # custom packages
  arandr = prev.arandr.overrideAttrs (_: {
    src = inputs.arandr;
  });

  inherit (inputs.home-manager.packages.${prev.system}) home-manager;

  inherit (inputs.gh-gfm-preview.packages.${prev.system}) gh-gfm-preview;

  inherit (inputs.nix-proxy-manager.packages.${prev.system}) nix-proxy-manager;

  generate-gh-actions =
    let
      mkGHActionsYAML =
        name:
        prev.runCommand name
          {
            buildInputs = with prev; [
              actionlint
              yj
            ];
            json = builtins.toJSON (import ../actions/${name}.nix);
            passAsFile = [ "json" ];
          }
          ''
            mkdir -p $out
            yj -jy < "$jsonPath" > $out/${name}.yml
            actionlint -verbose $out/${name}.yml
          '';
      ghActionsYAMLs = map mkGHActionsYAML [
        "build-and-cache"
        "update-flakes"
        "update-flakes-after"
        "validate-flakes"
      ];
      resultDir = ".github/workflows";
    in
    prev.writeShellApplication {
      name = "generate-gh-actions";
      text = ''
        rm -rf "${resultDir}"
        mkdir -p "${resultDir}"
        for dir in ${builtins.toString ghActionsYAMLs}; do
          cp -f $dir/*.yml "${resultDir}"
        done
        echo Done!
      '';
    };

  open-browser = prev.callPackage ../packages/open-browser { };

  neovim-standalone =
    let
      hostname = "neovim-standalone";
      hm =
        (outputs.lib.mkHomeConfig {
          inherit hostname;
          inherit (prev) system;
          configuration = {
            catppuccin = {
              # to make flake check happy
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
          };
        }).homeConfigurations.${hostname};
    in
    hm.config.programs.neovim.finalPackage.override {
      luaRcContent = hm.config.xdg.configFile."nvim/init.lua".text;
      wrapRc = true;
    };

  nix-cleanup = prev.callPackage ../packages/nix-cleanup { };

  nixos-cleanup = final.nix-cleanup.override { isNixOS = true; };

  darwin-cleanup = final.nix-cleanup.override { isNixDarwin = true; };

  nix-whereis = prev.callPackage ../packages/nix-whereis { };

  run-bg-alias = name: command: prev.callPackage ../packages/run-bg-alias { inherit name command; };
}
