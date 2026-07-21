{ lib }:

let
  # Core tool permissions (file operations, search, etc.)
  basicToolPermissions = [
    "Read"
    "Edit"
    "Write"
    "Glob"
    "Grep"
    "Agent"
  ];

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

  # Allowed shell commands (read-only and safe operations)
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
    "jj desc"
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
    "gh auth"
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
rec {
  inherit
    allowedShellCommands
    basicToolPermissions
    deniedShellCommands
    ;

  # Claude Code format: Bash(command:*)
  claudeAllowedBashPermissions = map (command: "Bash(${command}:*)") allowedShellCommands;

  claudeDeniedBashPermissions = map (command: "Bash(${command}:*)") deniedShellCommands;

  claudeFullPermissions = claudeAllowedBashPermissions ++ basicToolPermissions;

  # Codex format: list of command parts for prefix rules
  codexAllowedPrefixRules = map (command: lib.strings.splitString " " command) allowedShellCommands;

  # Gemini format: run_shell_command(command)
  geminiAllowedTools = map (command: "run_shell_command(${command})") allowedShellCommands;

  geminiAllowedPolicyRules = map (command: {
    toolName = "run_shell_command";
    commandPrefix = command;
    decision = "allow";
    priority = 100;
  }) allowedShellCommands;
}
