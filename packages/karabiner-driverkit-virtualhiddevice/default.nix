{
  fetchurl,
  stdenv,
  driverKitExtVersion ? "6.2.0",
}:

stdenv.mkDerivation {
  pname = "Karabiner-DriverKit-VirtualHIDDevice";
  version = driverKitExtVersion;
  src = fetchurl {
    url = "https://github.com/pqrs-org/Karabiner-DriverKit-VirtualHIDDevice/releases/download/v${driverKitExtVersion}/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg";
    sha256 = "sha256-noxGI58HSBYSQeQkRIV5ASJOXIL1tYoXMd9McL8HNqg=";
  };

  buildInputs = [ ];
  dontUnpack = true;
  installPhase = ''
    install -Dm644 $src $out/Karabiner-DriverKit-VirtualHIDDevice-${driverKitExtVersion}.pkg
  '';
}
