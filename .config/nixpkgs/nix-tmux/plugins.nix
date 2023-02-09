{ pkgs, lib, ... }:

{
  battery = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "battery";
    version = "unstable-2021-01-03";
    src = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tmux-battery";
      rev = "5c52d4f7f80384de0781c2277a8989ba98fae507";
      sha256 = "+ZFbNY17LnuD4k8YfM8KuIsy2zq78YburDQKKHnzeVw=";
    };
  };
}
