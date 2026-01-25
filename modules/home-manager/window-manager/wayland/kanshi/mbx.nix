[
  {
    profile.name = "undocked";
    profile.outputs = [
      {
        criteria = "eDP-1";
        status = "enable";
      }
    ];
  }
  {
    profile.name = "docked";
    profile.outputs = [
      {
        criteria = "LG Electronics LG HDR 4K 0x0003D6BE";
        status = "enable";
        scale = 1.5;
      }
      {
        criteria = "eDP-1";
        status = "disable";
      }
    ];
  }
]
