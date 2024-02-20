{ lib, ... }:

rec {
  isNvidia = osConfig:
    let
      videoDrivers = osConfig.services.xserver.videoDrivers or [ ];
    in
    builtins.elem "nvidia" videoDrivers;

  shortPathWithSep = with lib.strings;
    (sep: path: concatStringsSep sep (map (substring 0 1) (splitString "/" path)));

  shortPath = shortPathWithSep "/";

  capitalizeString = (str:
    let
      head = lib.strings.toUpper (builtins.substring 0 1 str);
      tail = builtins.concatStringsSep "" (
        builtins.tail (lib.stringToCharacters str)
      );
    in
    head + tail);
}
