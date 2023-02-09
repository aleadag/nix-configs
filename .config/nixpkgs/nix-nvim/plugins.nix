{ pkgs, lib }:

{
  neoscroll-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "neoscroll-nvim";
    version = "2022-06-16";
    src = pkgs.fetchFromGitHub {
        owner = "karb94";
        repo = "neoscroll.nvim";
        rev = "71c8fadd60362383e5e817e95f64776f5e2737d8";
        sha256 = "0OaoqN9kmS2AAEKM+cfzLjPwgD0j5P+bmBlblmsbkvU=";
    };
    meta.homepage = "https://github.com/karb94/neoscroll.nvim";
    };

  zenmode-nvim = pkgs.vimUtils.buildVimPlugin rec {
    pname = "zenmode-nvim";
    version = "2023-02-08";
    src = pkgs.fetchFromGitHub {
        owner = "folke";
        repo = "zen-mode.nvim";
        rev = "3c92f503823088862ca2a7809d1c7edc90fb92fa";
        sha256 = "F/BKOdFjm8SCCvWWry+n1OLUNQ9y/Mp0Y3batkJ4jdA=";
    };
    meta.homepage = "https://github.com/folke/zen-mode.nvim";
    };

    indent-blankline-nvim = pkgs.vimUtils.buildVimPlugin rec {
      pname = "indent-blankline-nvim";
      version = "2.18.4";
      src = pkgs.fetchFromGitHub {
        owner = "lukas-reineke";
        repo = "indent-blankline.nvim";
        rev = "6177a59552e35dfb69e1493fd68194e673dc3ee2";
        sha256 = "V020Sd2AcbEUvlnXffCDFBgVZnHCVUO16bfKJNn6Xq8=";
      };
      meta.homepage = "https://github.com/lukas-reineke/indent-blankline.nvim";
    };

    keymap-layer-nvim = pkgs.vimUtils.buildVimPlugin rec {
      pname = "keymap-layer-nvim";
      version = "2022-06-23";
      src = pkgs.fetchFromGitHub {
        owner = "anuvyklack";
        repo = "keymap-layer.nvim";
        rev = "f45540bdc435a0627467cbf5255fb2eba416b732";
        sha256 = "RTY1CvqxjAOHWwuTRbV6MTQUnK58ppBeXQCobc5K/rk=";
      };
      meta.homepage = "https://github.com/anuvyklack/keymap-layer.nvim";
    };

    hydra-nvim = pkgs.vimUtils.buildVimPlugin rec {
      pname = "hydra-nvim";
      version = "2022-06-25";
      src = pkgs.fetchFromGitHub {
        owner = "anuvyklack";
        repo = "hydra.nvim";
        rev = "249a19a4c95b9d0602918623a476196bf6956d5f";
        sha256 = "zlbYKweWaERamQDJGX2sjiKd2DTCfbR9sbfjvRtmDBU=";
      };
      meta.homepage = "https://github.com/anuvyklack/hydra.nvim";
    };
}

