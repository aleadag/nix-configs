{ lib
, stdenvNoCC
, bash
, shellcheck
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

    ${lib.getExe shellcheck} set-nix-proxy.sh reset-nix-proxy.sh

    runHook postCheck
  '';
})
