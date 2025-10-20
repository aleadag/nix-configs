{
  config,
  pkgs,
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
    fsmonitor.enable = lib.mkEnableOption "fsmonitor config" // {
      default = true;
    };
    gh.enable = lib.mkEnableOption "GitHub CLI config" // {
      default = true;
    };
    git-sync.enable = lib.mkEnableOption "git-sync of notes";
    mergiraf.enable = lib.mkEnableOption "Mergiraf config" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages =
        with pkgs;
        lib.optionals cfg.mergiraf.enable [
          mergiraf
        ];
      shellAliases = {
        g = "git";
      };
    };

    programs.git = {
      enable = true;

      attributes = lib.mkIf cfg.mergiraf.enable [
        "* merge=mergiraf"
      ];

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

      lfs = {
        enable = true;
        skipSmudge = true;
      };

      includes = [ { path = "~/.config/git/local"; } ];

      settings = {
        user = {
          name = config.meta.fullname;
          inherit (config.meta) email;
        };

        alias = {
          branch-cleanup = ''!git branch --merged | egrep -v "(^\*|master|main|dev|development)" | xargs git branch -d #'';
          hist = "log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short";
          lol = "log --graph --decorate --oneline --abbrev-commit";
          lola = "log --graph --decorate --oneline --abbrev-commit --all";
          work = "log --pretty=format:'%h%x09%an%x09%ad%x09%s'";
        };
        init.defaultBranch = "main";
        branch.sort = "-committerdate";
        color.ui = true;
        column.ui = "auto";
        commit.verbose = true;
        core = {
          editor = "nvim";
          fsmonitor = cfg.fsmonitor.enable;
          untrackedCache = cfg.fsmonitor.enable;
          whitespace = "trailing-space,space-before-tab,indent-with-non-tab";
        };
        checkout = {
          defaultRemote = "origin";
        };
        diff = {
          algorithm = "histogram";
          colorMoved = "plain";
          mnemonicPrefix = true;
          renames = true;
        };
        fetch = {
          prune = true;
          pruneTags = true;
        };
        github = {
          user = "aleadag";
        };
        merge = {
          mergiraf = lib.mkIf cfg.mergiraf.enable {
            name = "mergiraf";
            driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
          };
          conflictstyle = if cfg.mergiraf.enable then "diff3" else "zdiff3";
          tool = "nvim -d";
        };
        pull.rebase = true;
        push = {
          autoSetupRemote = true;
          followTags = true;
          default = "simple";
        };
        rebase = {
          autoSquash = true;
          autoStash = true;
          updateRefs = true;
        };
        rerere = {
          enabled = true;
          autoupdate = true;
        };
        tag.sort = "-version:refname";
        safe.bareRepository = "explicit";

        # for git-sync
        # https://github.com/simonthum/git-sync?tab=readme-ov-file#options
        branch.main = {
          sync = true;
          syncNewFiles = true;
        };
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true; # use n and N to move between diff sections
      };
    };

    programs.git-cliff.enable = true;

    programs.gh = {
      inherit (cfg.gh) enable;
      extensions = with pkgs; [
        gh-dash
        gh-markdown-preview
      ];
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
        prompt = "enabled";
        aliases = {
          co = "pr checkout";
        };
      };
    };

    services.git-sync = {
      inherit (cfg.git-sync) enable;

      repositories = {
        leetcode = {
          path = "${config.home.homeDirectory}/.local/share/nvim/leetcode";
          uri = "git+ssh://git@github.com:aleadag/leetcode.git";
          interval = 1 * 60 * 60;
        };
      };
    };
  };
}
