{ pkgs, lib }:

{
  hydra-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "hydra-nvim";
    version = "2023-02-06";
    src = pkgs.fetchFromGitHub {
      owner = "anuvyklack";
      repo = "hydra.nvim";
      rev = "3ced42c0b6a6c85583ff0f221635a7f4c1ab0dd0";
      sha256 = "MBlC7qQMVNNfOFcvTnw1DREOS9QWoI4zsyu3QYqIkLc=";
    };
    meta.homepage = "https://github.com/anuvyklack/hydra.nvim";
  };

  litee-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "litee-nvim";
    version = "2022-12-11";
    src = pkgs.fetchFromGitHub {
      owner = "ldelossa";
      repo = "litee.nvim";
      rev = "bf366a1414fd0f9401631ac8884f2f9fa4bf18d2";
      sha256 = "uC7FQlTwyMI7rSF4MzQSMTlfD4iqfjhIcY23csHig84=";
    };
    meta.homepage = "https://github.com/ldelossa/litee.nvim";
  };

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
