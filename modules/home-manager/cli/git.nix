{
  config,
  flake,
  lib,
  ...
}:

let
  cfg = config.home-manager.cli.git;
in
{
  options.home-manager.cli.git = {
    enable = lib.mkEnableOption "Git config" // {
      default = config.home-manager.cli.enable;
    };
    enableGh = lib.mkEnableOption "GitHub CLI config" // {
      default = true;
    };
    enableGitSync = lib.mkEnableOption "git-sync of notes";
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      g = "git";
      gu = "gitui";
    };

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

      delta.enable = true;
      delta.options = {
        navigate = true; # use n and N to move between diff sections
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

    programs.gitui = {
      enable = true;
      # Note:
      # If the default key layout is lower case,
      # and you want to use `Shift + q` to trigger the exit event,
      # the setting should like this `exit: Some(( code: Char('Q'), modifiers: "SHIFT")),`
      # The Char should be upper case, and the modifier should be set to "SHIFT".
      #
      # Note:
      # find `KeysList` type in src/keys/key_list.rs for all possible keys.
      # every key not overwritten via the config file will use the default specified there
      keyConfig = # rust
        ''
          (
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
            )
        '';
    };

    services.git-sync = {
      enable = cfg.enableGitSync;
      repositories.notes = {
        path = "${config.home.homeDirectory}/notes";
        uri = "git+ssh://git@github.com:aleadag/notes.git";
        interval = 1 * 60 * 60;
      };
      repositories.leetcode = {
        path = "${config.home.homeDirectory}/.local/share/nvim/leetcode";
        uri = "git+ssh://git@github.com:aleadag/leetcode.git";
        interval = 1 * 60 * 60;
      };
    };
  };
}
