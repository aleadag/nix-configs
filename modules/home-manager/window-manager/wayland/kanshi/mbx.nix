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
        criteria = "Philips Consumer Electronics Company PHL 279C9 UHB2130005322";
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
