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

    xresources.extraConfig = with config.home-manager.desktop.theme.colors; ''
      #define base00 ${base}
      #define base01 ${mantle}
      #define base02 ${surface0}
      #define base03 ${surface1}
      #define base04 ${surface2}
      #define base05 ${text}
      #define base06 ${rosewater}
      #define base07 ${lavender}
      #define base08 ${red}
      #define base09 ${peach}
      #define base0A ${yellow}
      #define base0B ${green}
      #define base0C ${teal}
      #define base0D ${blue}
      #define base0E ${mauve}
      #define base0F ${flamingo}

      *foreground:   base05
      #ifdef background_opacity
      *background:   [background_opacity]base00
      #else
      *background:   base00
      #endif
      *cursorColor:  base05

      *color0:       base00
      *color1:       base08
      *color2:       base0B
      *color3:       base0A
      *color4:       base0D
      *color5:       base0E
      *color6:       base0C
      *color7:       base05

      *color8:       base03
      *color9:       base08
      *color10:      base0B
      *color11:      base0A
      *color12:      base0D
      *color13:      base0E
      *color14:      base0C
      *color15:      base07

      ! Note: colors beyond 15 might not be loaded (e.g., xterm, urxvt),
      ! use 'shell' template to set these if necessary
      *color16:      base09
      *color17:      base0F
      *color18:      base01
      *color19:      base02
      *color20:      base04
      *color21:      base06

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
