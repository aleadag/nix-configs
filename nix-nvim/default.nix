{ pkgs, lib, ... }:
let
  vim-plugins = import ./plugins.nix { inherit pkgs lib; };
  nixos-unstable = import <nixpkgs-unstable> { };
in {
  # nixpkgs.overlays = [
  #   (import (builtins.fetchTarball {
  #     url = https://github.com/nix-community/neovim-nightly-overlay/archive/master.tar.gz;
  #   }))
  # ];
  home.packages = with pkgs; [
    nixos-unstable.nodePackages.pyright
    nixos-unstable.tree-sitter
    nixos-unstable.code-minimap
    luaPackages.lua-lsp
    nodePackages.vim-language-server
    nodePackages.yaml-language-server
    nodePackages.bash-language-server
    nodePackages.vscode-json-languageserver-bin
    nodePackages.vscode-html-languageserver-bin
    nodePackages.vscode-css-languageserver-bin
    nodePackages.typescript-language-server
    rnix-lsp
    fd
  ];
  programs.neovim = {
    enable = true;
    package = nixos-unstable.neovim-unwrapped;
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
        editorconfig-vim
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
      ]
      # Unstable plugins
      ++ (with nixos-unstable.vimPlugins; [
        diffview-nvim
        nvim-base16
        nvim-treesitter.withAllGrammars
        lsp_extensions-nvim
        bufferline-nvim
        galaxyline-nvim
        nvim-tree-lua
        neoscroll-nvim
        zen-mode-nvim
        indent-blankline-nvim # using my own derivation because the nixpkgs still uses the master branch
        ChatGPT-nvim
        null-ls-nvim
        which-key-nvim
        telescope-fzf-native-nvim
        hydra-nvim
        litee-nvim
      ])
      # Customized plugins
      ++ (with vim-plugins; [ gh-nvim ]);

    extraConfig = ''
      lua << EOF
    '' + builtins.readFile ./init.lua + ''

      EOF'';
  };
}
