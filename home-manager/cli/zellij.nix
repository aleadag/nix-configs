{ config, lib, ... }: {

  options.home-manager.cli.zellij.enable = lib.mkEnableOption "Zellij config" // {
    default = config.home-manager.cli.enable;
  };

  config = lib.mkIf config.home-manager.cli.zellij.enable {
    programs.zellij = { enable = true; };

    # NOTE: the module only supports YAML config which is deprecated
    home.file.zellij = {
      target = ".config/zellij/config.kdl";
      text = /* kdl */''
        // simplified_ui true
        // default_layout "compact"
        // keybinds clear-defaults=true {
        //   normal {
        //     bind "Ctrl o" { SwitchToMode "tmux"; }
        //   }
        //   tmux {
        //     bind "Ctrl o" { SwitchToMode "Normal"; }
        //     bind "Esc" { SwitchToMode "Normal"; }

        //     bind "Ctrl e" { WriteChars "vi ."; Write 13; SwitchToMode "Normal"; }
        //     bind "Ctrl r" { WriteChars "kubie ctx"; Write 13; SwitchToMode "Normal"; }

        //     bind "Ctrl u" { CloseFocus; SwitchToMode "Normal"; }
        //     bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        //     bind "d" { Detach; }
        //     bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }

        //     bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
        //     bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
        //     bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
        //     bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }

        //     bind "y" { NewPane "Down"; SwitchToMode "Normal"; }
        //     bind "n" { NewPane "Right"; SwitchToMode "Normal"; }

        //     bind "c" { NewTab; SwitchToMode "Normal"; }
        //     bind "Ctrl l" { GoToNextTab; SwitchToMode "Normal"; }
        //     bind "Ctrl h" { GoToPreviousTab; SwitchToMode "Normal"; }
        //   }
        // }
        theme "catppuccin-frappe"
        themes {
          catppuccin-frappe {
            bg "#626880" // Surface2
            fg "#c6d0f5"
            red "#e78284"
            green "#a6d189"
            blue "#8caaee"
            yellow "#e5c890"
            magenta "#f4b8e4" // Pink
            orange "#ef9f76" // Peach
            cyan "#99d1db" // Sky
            black "#292c3c" // Mantle
            white "#c6d0f5"
          }
        }
      '';
    };
  };
}
