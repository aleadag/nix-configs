{ config, pkgs, lib, ... }: {
  options.home-manager.editor.helix.enable =
    lib.mkEnableOption "Helix editor config"
    // {
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
            command = lib.getExe pkgs.nil;
            config.nil.formatting.command = [ "${lib.getExe pkgs.nixpkgs-fmt}" ];
          };

          typescript-language-server = {
            command = "${pkgs.nodePackages.typescript-language-server}/bin/typescript-language-server";
            args = [ "--stdio" ];
            config =
              let
                inlayHints = {
                  includeInlayEnumMemberValueHints = true;
                  includeInlayFunctionLikeReturnTypeHints = true;
                  includeInlayFunctionParameterTypeHints = true;
                  includeInlayParameterNameHints = "all";
                  includeInlayParameterNameHintsWhenArgumentMatchesName = true;
                  includeInlayPropertyDeclarationTypeHints = true;
                  includeInlayVariableTypeHints = true;
                };
              in
              {
                typescript-language-server.source = {
                  addMissingImports.ts = true;
                  fixAll.ts = true;
                  organizeImports.ts = true;
                  removeUnusedImports.ts = true;
                  sortImports.ts = true;
                };

                typescript = { inherit inlayHints; };
                javascript = { inherit inlayHints; };

                hostInfo = "helix";
              };
          };

          # Disable until follow PR was merged to main stream
          # https://github.com/NixOS/nixpkgs/issues/335533
          # vscode-css-language-server = {
          #   command = "${pkgs.nodePackages.vscode-langservers-extracted}/bin/vscode-css-language-server";
          #   args = [ "--stdio" ];
          #   config = {
          #     provideFormatter = true;
          #     css.validate.enable = true;
          #     scss.validate.enable = true;
          #   };
          # };

          ruff-lsp = {
            command = lib.getExe pkgs.ruff-lsp;
          };
        };

        language =
          let
            deno = lang: {
              command = lib.getExe pkgs.deno;
              args = [ "fmt" "-" "--ext" lang ];
            };
          in
          [
            {
              name = "bash";
              auto-format = true;
              formatter = {
                command = lib.getExe pkgs.shfmt;
                args = [ "-i" "2" ];
              };
            }
            {
              name = "nix";
              auto-format = true;
              language-servers = [ "nil" ];
            }
            {
              name = "javascript";
              auto-format = true;
              formatter = deno "js";
              language-servers = [ "typescript-language-server" ];
            }
            {
              name = "typescript";
              auto-format = true;
              formatter = deno "ts";
              language-servers = [ "typescript-language-server" ];
            }
            {
              name = "json";
              formatter = deno "json";
            }
            {
              name = "markdown";
              auto-format = true;
              formatter = deno "md";
            }
            {
              name = "tsx";
              auto-format = true;
              formatter = deno "tsx";
            }
            {
              name = "svelte";
              auto-format = true;
            }
            {
              name = "python";
              language-servers = [ "pylsp" "ruff-lsp" ];
              formatter = {
                command = lib.getExe pkgs.black;
                args = [ "--quiet" "-" ];
              };
              auto-format = true;
            }
          ];
      };
    };
  };
}
