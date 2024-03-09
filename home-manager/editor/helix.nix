{ config, pkgs, lib, ... }:

{
  options.home-manager.editor.helix.enable = lib.mkEnableOption "Helix editor config" // {
    default = config.home-manager.editor.enable;
  };

  config = lib.mkIf config.home-manager.editor.helix.enable {
    programs.helix = {
      enable = true;
      # package = flake.inputs.helix.packages.${pkgs.system}.default;
      defaultEditor = true;

      settings = {
        theme = "catppuccin_${config.home-manager.desktop.theme.flavor}";

        editor = {
          color-modes = true;
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          indent-guides = {
            character = "╎";
            render = true;
          };
          line-number = "relative";
          lsp.display-messages = true;
          statusline = {
            left = [ "mode" "spinner" ];
            center = [ "file-name" ];
            right = [ "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
            separator = "│";
          };
        };

        keys.normal = {
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
          esc = [ "collapse_selection" "keep_primary_selection" ];
        };
      };

      languages = {
        language-server = {
          nil = {
            command = "${pkgs.nil}/bin/nil";
            config.nil = {
              formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
            };
          };
        };

        language = [
          {
            name = "nix";
            auto-format = true;
            language-servers = [ "nil" ];
          }
        ];
      };
    };
  };
}
