{
  description = "My configuration files";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # build helix from the source
    # https://github.com/helix-editor/helix/discussions/6062
    # helix = {
    #   url = "github:helix-editor/helix";
    #   inputs.flake-utils.follows = "flake-utils";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    # helpers
    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    # custom packages
    arandr = {
      url = "gitlab:thiagokokada/arandr";
      flake = false;
    };

    # neovim plugins
    oil-nvim = {
      url = "github:pi314ever/oil.nvim";
      flake = false;
    };

    # nnn plugins
    nnn-plugins = {
      url = "github:jarun/nnn";
      flake = false;
    };

    # ZSH plugins
    zim-completion = {
      url = "github:zimfw/completion";
      flake = false;
    };
    zim-environment = {
      url = "github:zimfw/environment";
      flake = false;
    };
    zim-input = {
      url = "github:zimfw/input";
      flake = false;
    };
    zim-git = {
      url = "github:zimfw/git";
      flake = false;
    };
    zim-ssh = {
      url = "github:zimfw/ssh";
      flake = false;
    };
    zim-utility = {
      url = "github:zimfw/utility";
      flake = false;
    };
    pure = {
      url = "github:sindresorhus/pure";
      flake = false;
    };
    zsh-autopair = {
      url = "github:hlissner/zsh-autopair";
      flake = false;
    };
    zsh-completions = {
      url = "github:zsh-users/zsh-completions";
      flake = false;
    };
    zsh-syntax-highlighting = {
      url = "github:zsh-users/zsh-syntax-highlighting";
      flake = false;
    };
    zsh-proxy = {
      url = "github:SukkaW/zsh-proxy";
      flake = false;
    };

    catppuccin-fish = {
      url = "github:catppuccin/fish";
      flake = false;
    };

    catppuccin-bat = {
      url = "github:catppuccin/bat";
      flake = false;
    };

    catppuccin-delta = {
      url = "github:catppuccin/delta";
      flake = false;
    };

    catppuccin-gitui = {
      url = "github:catppuccin/gitui";
      flake = false;
    };

    catppuccin-starship = {
      url = "github:catppuccin/starship";
      flake = false;
    };

    catppuccin-yazi = {
      url = "github:catppuccin/yazi";
      flake = false;
    };

    omf-proxy = {
      url = "github:oh-my-fish/plugin-proxy";
      flake = false;
    };

    bing-wallpaper-mac = {
      url = "github:lpikora/bing-wallpaper-daily-mac-multimonitor";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      lib = import ./lib inputs;
      inherit (lib) recursiveMergeAttrs mkGHActionsYAMLs mkHomeConfig;
    in
    recursiveMergeAttrs [
      {
        inherit lib;
        overlays.default = import ./overlays { flake = self; };
      }
      (mkHomeConfig {
        hostname = "t0";
        username = "alexander";
        system = "aarch64-darwin";
        homePath = "/Users";
        extraModules = [{
          home-manager = {
            cli.git.enableGitSync = true;
            darwin.bing-wallpaper.enable = false;
          };
        }];
      })

      (mkHomeConfig {
        hostname = "mbx";
        username = "awang";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [{
          home-manager = {
            desktop.enable = true;
          };
        }];
      })

      (mkHomeConfig {
        hostname = "fftai";
        username = "alexander";
        system = "x86_64-linux";
        homePath = "/home";
        extraModules = [{
          home-manager = {
            desktop = {
              enable = false;
              nixgl = {
                enable = true;
                package = self.outputs.legacyPackages."x86_64-linux".nixgl.auto.nixGLNvidia;
              };
              theme = {
                enable = true;
                gtk.enable = false;
                qt.enable = false;
              };
              wezterm.enable = true;
            };
            gui.enable = false;
          };
        }];
      })

      # GitHub Actions
      (mkGHActionsYAMLs [
        "build-and-cache"
        "update-flakes"
        "update-flakes-darwin"
        "validate-flakes"
      ])

      (flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in
        {
          legacyPackages = pkgs;
        }))
    ]; # END recursiveMergeAttrs
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://aleadag-nix-configs.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "aleadag-nix-configs.cachix.org-1:Dj7/n2rktn8tDPLfT+pEavG3wJfLkkOVBpd25O0+V/Q="
    ];
  };
}
