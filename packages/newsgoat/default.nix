{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "newsgoat";
  version = "3.6.0";

  src = fetchFromGitHub {
    owner = "jarv";
    repo = "newsgoat";
    rev = "v${version}";
    hash = "sha256-JGwu7kTKizFJff9PCApyjxHFJt7XVu8NJRsUjRIyumM=";
  };

  vendorHash = "sha256-ESlVral3mt66BNrZpo1XYvRbMNy+Q54+173I7PS+qZg=";

  ldflags = [
    "-w"
    "-X github.com/jarv/newsgoat/internal/version.GitHash=v${version}"
  ];

  meta = {
    description = "Terminal-based RSS reader";
    homepage = "https://github.com/jarv/newsgoat";
    license = lib.licenses.mit;
    mainProgram = "newsgoat";
  };
}
