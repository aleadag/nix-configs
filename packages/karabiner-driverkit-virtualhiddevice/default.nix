{
  fetchurl,
  stdenv,
  driverKitExtVersion ? "5.0.0",
}:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = driverKitExtVersion;
  # use /raw/main/dist/* from filetree
  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/raw/main/dist/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg";
    sha256 = "sha256-hKi2gmIdtjl/ZaS7RPpkpSjb+7eT0259sbUUbrn5mMc";
  };

  buildInputs = [ ];
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg
  '';
}
