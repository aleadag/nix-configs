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
        criteria = "DP-2";
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
