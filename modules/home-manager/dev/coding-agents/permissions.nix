{
  config ? { },
  lib ? pkgs.lib,
  pkgs ? null,
  ...
}:

let
  # Direct access to home-manager options with fallback to false
  hasJujutsu = config.home-manager.cli.jujutsu.enable or false;
  hasGit = (config.home-manager.cli.git.enable or false) || (config.home-manager.dev.enable or false);
  hasBeads = config.home-manager.dev.coding-agents.enable or false;
  hasJust = config.home-manager.dev.enable or false;
  hasGo = config.home-manager.dev.go.enable or false;
  hasNode = config.home-manager.dev.node.enable or false;
  hasNix = (config.home-manager.dev.nix.enable or false) || (config.home-manager.dev.enable or false);
  hasGh = config.home-manager.cli.gh.enable or false;
  hasTerraform = config.home-manager.dev.terraform.enable or false;
  hasSbt = config.home-manager.dev.scala.enable or false;

  # Dangerous commands that should be explicitly denied
  deniedShellCommands = [
    "rm -rf"
    "git push --force"
    "git reset --hard"
    "git clean -f"
    "terraform apply"
    "terraform destroy"
    "sbt publish"
  ];

  # Base Unix and text processing tools (always allowed)
  baseCommands = [
    "cat"
    "cd"
    "echo"
    "ls"
    "find"
    "file"
    "grep"
    "head"
    "jq"
    "tail"
    "wc"
    "pwd"
    "rg"
    "sed"
    "stat"
    "which"
    "tree"
    "mkdir"
    "sort"
    "uniq"
    "diff"
    "make"
  ];

  bdCommands = [
    "bd create"
    "bd close"
    "bd prime"
    "bd update"
    "bd ready"
    "bd show"
  ];

  gitCommands = [
    "git add"
    "git branch"
    "git commit"
    "git diff"
    "git log"
    "git ls-files"
    "git remote -v"
    "git rev-parse"
    "git show"
    "git stash list"
    "git status"
  ];

  jjCommands = [
    "jj abandon"
    "jj bookmark"
    "jj commit"
    "jj desc"
    "jj describe"
    "jj diff"
    "jj git"
    "jj log"
    "jj new"
    "jj root"
    "jj show"
    "jj status"
  ];

  justCommands = [
    "just build"
    "just lint"
    "just test"
    "just fmt"
  ];

  goCommands = [
    "go build"
    "go test"
    "go vet"
    "go fmt"
    "go mod tidy"
  ];

  nodeCommands = [
    "npm run"
    "npm test"
    "npm install"
    "npm ci"
    "npx"
    "node"
  ];

  nixCommands = [
    "nix build"
    "nix flake"
    "nix develop"
    "nix fmt"
    "nix eval"
    "nix log"
    "nix path-info"
    "nix search"
    "nixfmt"
    "statix check"
  ];

  ghCommands = [
    "gh auth"
    "gh pr"
    "gh issue"
    "gh repo view"
  ];

  terraformCommands = [
    "terraform fmt"
    "terraform validate"
    "terraform plan"
  ];

  sbtCommands = [
    "sbt"
  ];

  # Combine allowed commands gated by home-manager module availability
  allowedShellCommands =
    baseCommands
    ++ lib.optionals hasBeads bdCommands
    ++ lib.optionals hasGit gitCommands
    ++ lib.optionals hasJujutsu jjCommands
    ++ lib.optionals hasJust justCommands
    ++ lib.optionals hasGo goCommands
    ++ lib.optionals hasNode nodeCommands
    ++ lib.optionals hasNix nixCommands
    ++ lib.optionals hasGh ghCommands
    ++ lib.optionals hasTerraform terraformCommands
    ++ lib.optionals hasSbt sbtCommands;
in
{
  inherit
    allowedShellCommands
    deniedShellCommands
    ;
}
