{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "Alexander Wang";
    userEmail = "aleadag@gmail.com";
    aliases = {
      lol = "log --graph --decorate --oneline --abbrev-commit";
      lola = "log --graph --decorate --oneline --abbrev-commit --all";
      hist =
        "log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short";
      work = "log --pretty=format:'%h%x09%an%x09%ad%x09%s'";
    };
    delta.enable = true;
    delta.options.syntax-theme = "Catppuccin-frappe";
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
      #   http = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
      #   https = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
    };
  };

  programs.git-cliff.enable = true;

  # SSH proxy not working for now!!
  # https://github.com/extrawurst/gitui/issues/1194
  programs.gitui = {
    enable = true;
    theme = builtins.readFile (pkgs.fetchFromGitHub
      {
        owner = "catppuccin";
        repo = "gitui";
        rev = "39978362b2c88b636cacd55b65d2f05c45a47eb9";
        sha256 = "sha256-kWaHQ1+uoasT8zXxOxkur+QgZu1wLsOOrP/TL+6cfII=";
      } + "/theme/frappe.ron");
    keyConfig = ''(
      focus_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
      focus_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
      focus_above: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
      focus_below: Some(( code: Char('j'), modifiers: ( bits: 0,),)),

      open_help: Some(( code: F(1), modifiers: ( bits: 0,),)),

      move_left: Some(( code: Char('h'), modifiers: ( bits: 0,),)),
      move_right: Some(( code: Char('l'), modifiers: ( bits: 0,),)),
      move_up: Some(( code: Char('k'), modifiers: ( bits: 0,),)),
      move_down: Some(( code: Char('j'), modifiers: ( bits: 0,),)),
      popup_up: Some(( code: Char('p'), modifiers: ( bits: 2,),)),
      popup_down: Some(( code: Char('n'), modifiers: ( bits: 2,),)),
      page_up: Some(( code: Char('b'), modifiers: ( bits: 2,),)),
      page_down: Some(( code: Char('f'), modifiers: ( bits: 2,),)),
      home: Some(( code: Char('g'), modifiers: ( bits: 0,),)),
      end: Some(( code: Char('G'), modifiers: ( bits: 1,),)),
      shift_up: Some(( code: Char('K'), modifiers: ( bits: 1,),)),
      shift_down: Some(( code: Char('J'), modifiers: ( bits: 1,),)),

      edit_file: Some(( code: Char('I'), modifiers: ( bits: 1,),)),

      status_reset_item: Some(( code: Char('U'), modifiers: ( bits: 1,),)),

      diff_reset_lines: Some(( code: Char('u'), modifiers: ( bits: 0,),)),
      diff_stage_lines: Some(( code: Char('s'), modifiers: ( bits: 0,),)),

      stashing_save: Some(( code: Char('w'), modifiers: ( bits: 0,),)),
      stashing_toggle_index: Some(( code: Char('m'), modifiers: ( bits: 0,),)),

      stash_open: Some(( code: Char('l'), modifiers: ( bits: 0,),)),

      abort_merge: Some(( code: Char('M'), modifiers: ( bits: 1,),)),
    )'';
  };

  services.git-sync = {
    enable = true;
    repositories.notes = {
      path = "${config.home.homeDirectory}/notes";
      uri = "git@github.com:aleadag/notes.git";
      interval = 1 * 60 * 60;
    };
  };
}
