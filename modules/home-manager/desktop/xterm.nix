{
  config,
  pkgs,
  lib,
  ...
}:

{
  options.home-manager.desktop.xterm.enable = lib.mkEnableOption "Xterm config" // {
    default = config.home-manager.desktop.enable;
  };

  config = lib.mkIf config.home-manager.desktop.xterm.enable {
    home.packages = with pkgs; [
      hack-font
      xterm
    ];

    xresources.extraConfig = ''
      ! UXterm config
      UXTerm.termName: xterm-256color
      UXTerm.vt100.metaSendsEscape: true
      UXTerm.vt100.backarrowKey: false
      UXTerm.vt100.saveLines: 4096
      UXTerm.vt100.bellIsUrgent: true
      UXTerm.ttyModes: erase ^?

      UXTerm.vt100.translations: #override \n\
          Ctrl Shift <Key>C: copy-selection(CLIPBOARD) \n\
          Ctrl Shift <Key>V: insert-selection(CLIPBOARD)

      UXTerm.vt100.faceName: Hack:size=12

      ! Xterm config
      XTerm.termName: xterm-256color
      XTerm.vt100.metaSendsEscape: true
      XTerm.vt100.backarrowKey: false
      XTerm.vt100.saveLines: 4096
      XTerm.vt100.bellIsUrgent: true
      XTerm.ttyModes: erase ^?

      XTerm.vt100.translations: #override \n\
          Ctrl Shift <Key>C: copy-selection(CLIPBOARD) \n\
          Ctrl Shift <Key>V: insert-selection(CLIPBOARD)

      XTerm.vt100.faceName: Hack:size=12
    '';
  };
}
