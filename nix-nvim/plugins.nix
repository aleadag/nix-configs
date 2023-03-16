{ pkgs, lib }:

{
  gh-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "gh-nvim";
    version = "2022-12-11";
    src = pkgs.fetchFromGitHub {
      owner = "ldelossa";
      repo = "gh.nvim";
      rev = "bc731bb53909481995ac2edb4bf6418c051fec1a";
      sha256 = "BjzQe8wCNAx31vN9/RzF75U8ec5bytnaRrM0OHm1fpI=";
    };
    meta.homepage = "https://github.com/ldelossa/gh.nvim";
  };
}
