{ lib, ... }:
{
  fixColor = color: "0xff${lib.removePrefix "#" color}";
}
