{ config, flake, lib, ... }:

let
  cfg = config.home-manager.cli.git;
in
{
  options.home-manager.cli.git = {
    enable = lib.mkEnableOption "Git config" // {
      default = config.home-manager.cli.enable;
    };
    enableGh = lib.mkEnableOption "GitHub CLI config" // { default = true; };
  };

  config = lib.mkIf cfg.enable {

    programs.git = {
      enable = true;

      userName = config.mainUser.fullname;
      userEmail = config.mainUser.email;
      aliases = {
        branch-cleanup = ''!git branch --merged | egrep -v "(^\*|master|main|dev|development)" | xargs git branch -d #'';
        hist = "log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short";
        lol = "log --graph --decorate --oneline --abbrev-commit";
        lola = "log --graph --decorate --oneline --abbrev-commit --all";
        work = "log --pretty=format:'%h%x09%an%x09%ad%x09%s'";
      };

      ignores = [
        "*.swp"
        "*~"
        ".clj-kondo"
        ".dir-locals.el"
        ".DS_Store"
        ".lsp"
        ".projectile"
        "Thumbs.db"
      ];

      includes = [{ path = "${builtins.getAttr "catppuccin-delta" flake.inputs}/themes/${config.home-manager.desktop.theme.flavor}.gitconfig"; }];

      delta.enable = true;
      delta.options = {
        features = "side-by-side line-numbers decorations catppuccin-${config.home-manager.desktop.theme.flavor}";
      };
      lfs.enable = true;
      lfs.skipSmudge = true;
      extraConfig = {
        init.defaultBranch = "main";
        pull.ff = "only";
        merge.conflictstyle = "diff3";

        # for git-sync
        # https://github.com/simonthum/git-sync?tab=readme-ov-file#options
        branch.main.sync = true;
        branch.main.syncNewFiles = true;
      };
    };

    programs.git-cliff.enable = true;

    programs.gh = {
      enable = cfg.enableGh;
      settings = {
        # Workaround for https://github.com/nix-community/home-manager/issues/4744
        version = 1;
        git_protocol = "ssh";
        prompt = "enabled";
        pager = "less -RF";
      };
    };

    # SSH proxy not working for now!!
    # https://github.com/extrawurst/gitui/issues/1194
    programs.gitui = {
      enable = true;
      theme = builtins.readFile (builtins.getAttr "catppuccin-gitui" flake.inputs
        + "/theme/${config.home-manager.desktop.theme.flavor}.ron");
      keyConfig = ''(
      focus_right: Some(( code: Char('l'), modifiers: "")),
      focus_left: Some(( code: Char('h'), modifiers: "")),
      focus_above: Some(( code: Char('k'), modifiers: "")),
      focus_below: Some(( code: Char('j'), modifiers: "")),

      open_help: Some(( code: F(1), modifiers: "")),

      move_left: Some(( code: Char('h'), modifiers: "")),
      move_right: Some(( code: Char('l'), modifiers: "")),
      move_up: Some(( code: Char('k'), modifiers: "")),
      move_down: Some(( code: Char('j'), modifiers: "")),
      popup_up: Some(( code: Char('p'), modifiers: "CONTROL")),
      popup_down: Some(( code: Char('n'), modifiers: "CONTROL")),
      page_up: Some(( code: Char('b'), modifiers: "CONTROL")),
      page_down: Some(( code: Char('f'), modifiers: "CONTROL")),
      home: Some(( code: Char('g'), modifiers: "")),
      end: Some(( code: Char('G'), modifiers: "SHIFT")),
      shift_up: Some(( code: Char('K'), modifiers: "SHIFT")),
      shift_down: Some(( code: Char('J'), modifiers: "SHIFT")),

      edit_file: Some(( code: Char('I'), modifiers: "SHIFT")),

      status_reset_item: Some(( code: Char('U'), modifiers: "SHIFT")),

      diff_reset_lines: Some(( code: Char('u'), modifiers: "")),
      diff_stage_lines: Some(( code: Char('s'), modifiers: "")),

      stashing_save: Some(( code: Char('w'), modifiers: "")),
      stashing_toggle_index: Some(( code: Char('m'), modifiers: "")),

      stash_open: Some(( code: Char('l'), modifiers: "")),

      abort_merge: Some(( code: Char('M'), modifiers: "SHIFT")),
    )'';
    };

    # TODO: make it configurable
    services.git-sync = {
      enable = true;
      repositories.notes = {
        path = "${config.home.homeDirectory}/notes";
        uri = "git@github.com:aleadag/notes.git";
        interval = 1 * 60 * 60;
      };
    };
  };
}
