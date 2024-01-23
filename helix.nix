{ pkgs, ... }: {
  home.packages = with pkgs; [
    gopls
    marksman
    tailwindcss-language-server
    nodePackages.bash-language-server
    nodePackages.svelte-language-server
    nodePackages.typescript-language-server
    nodePackages.yaml-language-server
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "catppuccin_frappe";
      editor = {
        # true-color = true;
        bufferline = "multiple";
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
          left = [ "mode" "spinner" "version-control" "file-name" ];
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
        # vscode language servers. Have to set because helix expects vscode-{lang}-language-server, but the name in nix is {lang}-languageserver
        vscode-json-language-server = with pkgs.nodePackages; {
          command = "${vscode-json-languageserver-bin}/bin/json-languageserver";
          args = [ "--stdio" ];
        };

        vscode-html-language-server = with pkgs.nodePackages; {
          command = "${vscode-html-languageserver-bin}/bin/html-languageserver";
          args = [ "--stdio" ];
        };

        vscode-css-language-server = with pkgs.nodePackages; {
          command = "${vscode-css-languageserver-bin}/bin/css-languageserver";
          args = [ "--stdio" ];
          config = { provideFormatter = true; css = { validate = { enable = true; }; }; };
        };

        nil = {
          command = "${pkgs.nil}/bin/nil";
          config.nil = {
            formatting.command = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
          };
        };
      };

      language = [
        {
          name = "css";
          language-servers = [ "vscode-css-language-server" "tailwindcss-ls" ];
        }

        {
          name = "json";
          auto-format = true;
          formatter = {
            command = "${pkgs.dprint}/bin/dprint";
            args = [ "fmt" "--stdin" "json" ];
          };
        }

        {
          name = "nix";
          language-servers = [ "nil" ];
        }

        {
          name = "markdown";
          formatter = { command = "${pkgs.dprint}/bin/dprint"; args = [ "fmt" "--stdin" "md" ]; };
        }
      ];
    };
  };
}
