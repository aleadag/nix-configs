{ pkgs, lib, ... }:
let vim-plugins = import ./plugins.nix { inherit pkgs lib; };
in {
  # nixpkgs.overlays = [
  #   (import (builtins.fetchTarball {
  #     url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
  #   }))
  # ];
  home.packages = with pkgs; [
    nodePackages.pyright
    tree-sitter
    code-minimap
    luaPackages.lua-lsp
    nodePackages.vim-language-server
    nodePackages.yaml-language-server
    nodePackages.bash-language-server
    nodePackages.vscode-json-languageserver-bin
    nodePackages.vscode-html-languageserver-bin
    nodePackages.vscode-css-languageserver-bin
    nodePackages.typescript-language-server
    nodePackages.svelte-language-server
    rnix-lsp
    fd
    # go language server
    gopls
  ];
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins;
      [
        csv-vim
        vim-surround # fix config
        vim-repeat
        # vim-speeddating  # makes statusline buggy??
        vim-commentary
        vim-unimpaired
        vim-sleuth # adjusts shiftwidth and expandtab based on the current file
        vim-startify
        # vim-multiple-cursors, replaced by visual-multi
        vim-visual-multi
        gundo-vim
        vim-easy-align
        vim-table-mode
        vim-markdown
        ansible-vim
        vim-nix
        # vimspector
        popup-nvim
        plenary-nvim
        telescope-nvim
        telescope-symbols-nvim
        # telescope-media-files  # doesn't support wayland yet
        nvim-colorizer-lua
        nvim-lspconfig
        # completion-nvim
        cmp-nvim-lsp
        cmp-buffer
        cmp-path
        cmp-cmdline
        cmp-vsnip
        nvim-cmp
        lspkind-nvim
        gitsigns-nvim
        neogit
        nvim-autopairs
        vim-closetag
        friendly-snippets
        vim-vsnip
        nvim-web-devicons
        vim-devicons
        # vim-auto-save  # ?
        minimap-vim
        vim-easymotion
        quick-scope
        matchit-zip
        targets-vim
        vim-numbertoggle
        # vim-markdown-composer
        vimwiki
        pkgs.vimwiki-markdown
        vim-python-pep8-indent
        lsp_signature-nvim
        rust-tools-nvim
        keymap-layer-nvim
        bufexplorer
        markdown-preview-nvim
        diffview-nvim
        nvim-base16
        nvim-treesitter.withAllGrammars
        lsp_extensions-nvim
        bufferline-nvim
        galaxyline-nvim
        nvim-tree-lua
        neoscroll-nvim
        zen-mode-nvim
        indent-blankline-nvim
        ChatGPT-nvim
        null-ls-nvim
        which-key-nvim
        telescope-fzf-native-nvim
        hydra-nvim
        refactoring-nvim
        vimtex
        octo-nvim
        dart-vim-plugin
      ]
      # Customized plugins
      ++ (with vim-plugins; [ ]);

    extraConfig = ''
      lua << EOF
    '' + builtins.readFile ./init.lua + ''

      EOF'';
  };
}