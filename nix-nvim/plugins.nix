{ pkgs, lib }:

{
  gh-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "gh-nvim";
    version = "2023-10-25";
    src = pkgs.fetchFromGitHub {
      owner = "ldelossa";
      repo = "gh.nvim";
      rev = "bd25740ca4dfbe6702eb7ffbcf8de105be3b5c20";
      sha256 = "BjzQe8wCNAx31vN9/RzF75U8ec5bytnaRrM0OHm1fpI=";
    };
    meta.homepage = "https://github.com/ldelossa/gh.nvim";
  };
}
