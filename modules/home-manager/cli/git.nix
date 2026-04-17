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
    gh.enable = lib.mkEnableOption "GitHub CLI config" // {
      default = true;
    };
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

    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          navigate = true; # use n and N to move between diff sections
        };
      };

      gh = {
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

      git = {
        enable = true;

        attributes = lib.mkIf cfg.mergiraf.enable [
          "* merge=mergiraf"
        ];

        ignores = [
          "**/.claude/settings.local.json"
          "**/CLAUDE.local.md"
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
          alias =
            let
              git = lib.getExe config.programs.git.package;
              awk = lib.getExe pkgs.gawk;
              xargs = lib.getExe' pkgs.findutils "xargs";
            in
            {
              branch-cleanup = ''!${git} fetch --prune && ${git} for-each-ref --format '%(refname:short) %(upstream:track)' refs/heads | ${awk} '$2 == "[gone]" {print $1}' | ${xargs} -r git branch -D'';
              # Restores the commit message from a failed commit for some reason
              fix-commit = ''!${git} commit -F "$(${git} rev-parse --git-dir)/COMMIT_EDITMSG" --edit'';
              pushf = "push --force-with-lease";
              logs = "log --show-signature";
            };
          branch.sort = "-committerdate";
          checkout = {
            defaultRemote = "origin";
          };
          color.ui = true;
          column.ui = "auto";
          commit.verbose = true;
          core = {
            editor = "nvim";
            whitespace = "trailing-space,space-before-tab,indent-with-non-tab";
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
          init.defaultBranch = "main";
          merge = {
            conflictstyle = if cfg.mergiraf.enable then "diff3" else "zdiff3";
            mergiraf = lib.mkIf cfg.mergiraf.enable {
              name = "mergiraf";
              driver = "mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L";
            };
            tool = "nvim -d";
          };
          pull.rebase = true;
          push = {
            autoSetupRemote = true;
            default = "simple";
            followTags = true;
          };
          rebase = {
            autoSquash = true;
            autoStash = true;
            updateRefs = true;
          };
          rerere = {
            autoupdate = true;
            enabled = true;
          };
          safe.bareRepository = "explicit";
          tag.sort = "-version:refname";
          user = {
            name = config.meta.fullname;
            inherit (config.meta) email;
          };
        };
      };

      git-cliff.enable = true;

      lazygit.enable = true;
    };
  };
}
