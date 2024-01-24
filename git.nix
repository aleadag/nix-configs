{ ... }:
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
      #   http = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
      #   https = {
      #     proxy = socks5://127.0.0.1:7891;
      #   };
    };
  };

  programs.git-cliff.enable = true;
}
