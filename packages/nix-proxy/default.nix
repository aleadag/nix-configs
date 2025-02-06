{
  lib,
  stdenvNoCC,
  bash,
  shellcheck,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  name = "nix-proxy";

  src = ./.;

  buildInputs = [ bash ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp *.sh $out/bin/
    chmod +x $out/bin/*.sh

    runHook postInstall
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    ${lib.getExe shellcheck} nix-set-proxy.sh nix-reset-proxy.sh

    runHook postCheck
  '';
})
