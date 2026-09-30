{
  lib,
  fetchFromGitHub,
  rustPlatform,
  python3,
}:

rustPlatform.buildRustPackage rec {
  pname = "herdr-beads";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "miiraheart";
    repo = "herdr-beads";
    rev = "bef9e42a2dc915be65d87d96a8843301d3457a83";
    hash = "sha256-TLcaLuMiUQwMOeku7GyWqkId3hfzuRXMUbL5G2Xys2Q=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  postInstall = ''
    mkdir -p $out/target/release
    ln -s $out/bin/herdr-beads $out/target/release/herdr-beads
    cp herdr-plugin.toml $out/
    cp -r scripts $out/
    chmod +x $out/scripts/*.sh
    substituteInPlace $out/scripts/lib.sh \
      --replace-fail "python3" "${python3}/bin/python3"
  '';

  meta = {
    description = "A beads (bd) task board for herdr";
    homepage = "https://github.com/miiraheart/herdr-beads";
    license = lib.licenses.mit;
    mainProgram = "herdr-beads";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
