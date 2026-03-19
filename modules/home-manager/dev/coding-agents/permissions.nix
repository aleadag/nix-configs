{ lib }:

let
  allowedShellCommands = [
    "cat"
    "cd"
    "echo"
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
    "jj abandon"
    "jj bookmark"
    "jj commit"
    "jj describe"
    "jj diff"
    "jj git"
    "jj log"
    "jj new"
    "jj root"
    "jj show"
    "jj status"
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
    "sbt"
    "npm run"
    "npm test"
    "npm install"
    "npm ci"
    "npx"
    "node"
    "go build"
    "go test"
    "go vet"
    "go fmt"
    "go mod tidy"
    "make"
    "terraform fmt"
    "terraform validate"
    "terraform plan"
    "gh pr"
    "gh issue"
    "gh repo view"
    "nix build"
    "nix flake"
    "nix develop"
    "nix fmt"
    "nix eval"
    "nix log"
    "nix path-info"
    "nix search"
    "nixfmt"
  ];
in
{
  inherit allowedShellCommands;

  claudeAllowedBashPermissions = map (command: "Bash(${command}:*)") allowedShellCommands;

  codexAllowedPrefixRules = map (command: lib.strings.splitString " " command) allowedShellCommands;

  geminiAllowedTools = map (command: "run_shell_command(${command})") allowedShellCommands;

  geminiAllowedPolicyRules = map (command: {
    toolName = "run_shell_command";
    commandPrefix = command;
    decision = "allow";
    priority = 100;
  }) allowedShellCommands;
}
