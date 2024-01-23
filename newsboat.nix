{ config, pkgs, ... }:
let
  add-to-instapaper =
    pkgs.callPackage ./scripts/add-to-instapaper.nix { inherit config; };
in
{
  programs.newsboat = {
    enable = true;
    urls = [
      {
        url = "https://rsshub.app/cls/telegraph";
        tags = [ "财经" ];
      }
      {
        url = "https://hnrss.org/newest?points=100";
        tags = [ "技术" ];
      }
      {
        url = "http://feeds.bbci.co.uk/news/world/rss.xml";
        tags = [ "新闻" ];
      }
      {
        url = "https://news.mingpao.com/rss/pns/s00001.xml";
        tags = [ "新闻" ];
      }
      {
        url = "http://www.zhihu.com/rss";
        tags = [ "视野" ];
      }
      {
        url = "http://www.matrix67.com/blog/feed";
        tags = [ "视野" ];
      }
      { url = "https://www.williamlong.info/rss.xml"; }
      { url = "https://feeds.appinn.com/appinns/"; }
      { url = "https://feeds.bbci.co.uk/zhongwen/simp/rss.xml"; }
    ];
    extraConfig = ''
      bookmark-cmd ${add-to-instapaper}/bin/add-to-instapaper
      bookmark-autopilot yes
      bind-key i bookmark

      # Dark solarized color scheme for newsbeuter
      color background         default   default
      color listnormal         default   default
      color listnormal_unread  default   default
      color listfocus          black     yellow
      color listfocus_unread   black     yellow
      color info               default   black
      color article            default   default

      # highlights
      highlight article "^(Title):.*$" blue default
      highlight article "https?://[^ ]+" red default
      highlight article "\\[image\\ [0-9]+\\]" green default
    '';
  };
}
