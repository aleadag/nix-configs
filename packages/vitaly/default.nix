{
  apple-sdk,
  fetchFromGitHub,
  lib,
  pkg-config,
  rustPlatform,
  stdenv,
  udev,
}:

rustPlatform.buildRustPackage rec {
  pname = "vitaly";
  version = "0.1.32";

  src = fetchFromGitHub {
    owner = "bskaplou";
    repo = "vitaly";
    rev = "v${version}";
    hash = "sha256-u1OmH2AeskcjNB1ac6iSBaA0Xyea+tB8f5F/LCzafj4=";
  };

  cargoHash = "sha256-HBJFOi3KrjIepGaPwtv/39sQotvQPae9y2rdPJ/uQ8k=";

  nativeBuildInputs = [ pkg-config ];

  buildInputs = lib.optionals stdenv.isLinux [ udev ] ++ lib.optionals stdenv.isDarwin [ apple-sdk ];

  meta = {
    description = "VIA/Vial API client and CLI tool for guiless keyboard configuration";
    homepage = "https://github.com/bskaplou/vitaly";
    license = lib.licenses.mit;
    mainProgram = "vitaly";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
