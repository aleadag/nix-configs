{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "cc-connect";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "chenhg5";
    repo = "cc-connect";
    rev = "v${version}";
    hash = "sha256-h5rZj6MXvrtT49mhtSFfeOnV28ib11a8jsgWbdQcGgM=";
  };

  vendorHash = "sha256-Bw7ZnPrDRAsk7D69rINXIiDDx5QhDFZMK3XDjBqKtBc=";

  subPackages = [ "cmd/cc-connect" ];
  tags = [ "no_web" ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=v${version}"
  ];

  meta = {
    description = "Bridge local AI coding agents to messaging platforms";
    homepage = "https://github.com/chenhg5/cc-connect";
    license = lib.licenses.mit;
    mainProgram = "cc-connect";
  };
}
