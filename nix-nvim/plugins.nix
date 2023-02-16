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
}
