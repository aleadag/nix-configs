{
  fetchFromGitHub,
  darwin,
  ...
}:

darwin.apple_sdk.stdenv.mkDerivation rec {
  pname = "JankyBorders";
  version = "unstable-2024-12-17";

  src = fetchFromGitHub {
    owner = "FelixKratz";
    repo = pname;
    rev = "522a2d3f9ef22263e79bc7fa696fed911b0faa3b";
    hash = "sha256-qH1ectK4avjQ7XaDXAUjsgVqCzr+JBCx46wz+Y1uIbY=";
  };

  buildInputs = with darwin.apple_sdk.frameworks; [
    AppKit
    SkyLight
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/borders $out/bin/
  '';

  meta = {
    description = "Fancy borders for macOS windows";
    homepage = "https://github.com/FelixKratz/JankyBorders";
    license = "MIT";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    maintainers = [ "aleadag" ];
    mainProgram = "borders";
  };
}
