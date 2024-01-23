{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Alexander Wang";
    userEmail = "aleadag@gmail.com";
    aliases = {
      hist =
        "log --pretty=format:'%C(yellow)[%ad]%C(reset) %C(green)[%h]%C(reset) | %C(red)%s %C(bold red){{%an}}%C(reset) %C(blue)%d%C(reset)' --graph --date=short";
    };
    delta.enable = true;
    delta.options.syntax-theme = "gruvbox-dark";
    lfs.enable = true;
    lfs.skipSmudge = true;
    # extraConfig = {
    #   http = {
    #     proxy = socks5://127.0.0.1:7891;
    #   };
    #   https = {
    #     proxy = socks5://127.0.0.1:7891;
    #   };
    # };
  };

  programs.git-cliff = { enable = true; };
}
