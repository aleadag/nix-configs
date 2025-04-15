{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.nix-darwin.yabai;
  catppuccin = import ../catppuccin.nix;
  date-time-sh = pkgs.writeShellScriptBin "date-time.sh" ''
    sketchybar -m --set $NAME label="$(date '+%a %d %b %H:%M')"
  '';
  spaces-sh = pkgs.writeShellScriptBin "spaces.sh" ''
    SPACE_ICONS=("" "" "" "" "")
    SPACE_CLICK_SCRIPTS=(
      "open -a 'Google Chrome.app'"
      "$HOME/.nix-profile/bin/kitty"
      "open -a Cursor.app"
      "open -a WeChat.app"
      "open -a Finder.app"
    )

    for i in "''${!SPACE_ICONS[@]}"
    do
      sid=$(($i+1))

      # 设置padding，第一个空间使用12，其他使用7
      if [ $i -eq 0 ]; then
        padding_left=12
      else
        padding_left=7
      fi

      sketchybar -m --add space space.$sid left \
        --set space.$sid associated_space=$sid \
        --set space.$sid icon="''${SPACE_ICONS[$i]}" \
        --set space.$sid icon.padding_left=8 \
        --set space.$sid icon.padding_right=0 \
        --set space.$sid icon.highlight_color=${catppuccin.frappe.red} \
        --set space.$sid label="$sid" \
        --set space.$sid label.padding_right=8 \
        --set space.$sid label.padding_left=6 \
        --set space.$sid label.highlight_color=${catppuccin.frappe.red} \
        --set space.$sid background.color=${catppuccin.frappe.surface1} \
        --set space.$sid background.height=21 \
        --set space.$sid background.padding_left=$padding_left \
        --set space.$sid click_script="yabai -m space --focus $sid; ''${SPACE_CLICK_SCRIPTS[$i]}"
    done
  '';
  top-mem-sh = pkgs.writeShellScriptBin "top-mem.sh" ''
    # MUST use /bin/ps, otherwise it will complain:
    # ps: rss: requires entitlement
    TOPMEM=$(/bin/ps axo "rss" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0fMB %s\n", $1 / 1024, $2}' | sed -e 's/com.apple.//g')
    MEM=$(echo $TOPMEM | sed -nr 's/([^MB]+).*/\1/p')
    sketchybar -m --set $NAME label="$TOPMEM"
  '';
  cpu-sh = pkgs.writeShellScriptBin "cpu.sh" ''
    CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
    CPU_INFO=$(/bin/ps -eo pcpu,user)
    CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
    CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
    sketchybar -m --set  cpu_percent label=$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", ($1 + $2)*100}')%
  '';
  caffeine-sh = pkgs.writeShellScriptBin "caffeine.sh" ''
    if pgrep -q 'caffeinate'
    then
      sketchybar --set $NAME icon="󰅶"
    else
      sketchybar --set $NAME icon="󰛊"
    fi
  '';
  caffeine-click-sh = pkgs.writeShellScriptBin "caffeine-click.sh" ''
    if pgrep -q 'caffeinate'
    then
      killall caffeinate
      sketchybar --set $NAME icon="󰛊"
    else
      caffeinate -d & disown
      sketchybar --set $NAME icon="󰅶"
    fi
  '';
  battery-sh = pkgs.writeShellScriptBin "battery.sh" ''
    if pmset -g ac | grep -q 'Family Code = 0x0000' # No battery (i.e. Mac Mini, Mac Pro, etc.)
    then
      sketchybar \
        --set $NAME \
          icon.color=${catppuccin.frappe.teal} \
          icon="󰚥" \
          label="AC"
    else
      data=$(pmset -g batt)
      battery_percent=$(echo $data | grep -Eo "[0-9]+%" | cut -d% -f1)
      charging=$(echo $data | grep 'AC Power')

      # 根据电量选择颜色和图标
      case "$battery_percent" in
        100)    icon="󰁹"; color=${catppuccin.frappe.green} ;;
        9[0-9]) icon="󰂂"; color=${catppuccin.frappe.green} ;;
        8[0-9]) icon="󰂁"; color=${catppuccin.frappe.green} ;;
        7[0-9]) icon="󰂀"; color=${catppuccin.frappe.teal} ;;
        6[0-9]) icon="󰁿"; color=${catppuccin.frappe.teal} ;;
        5[0-9]) icon="󰁾"; color=${catppuccin.frappe.blue} ;;
        4[0-9]) icon="󰁽"; color=${catppuccin.frappe.blue} ;;
        3[0-9]) icon="󰁼"; color=${catppuccin.frappe.yellow} ;;
        2[0-9]) icon="󰁻"; color=${catppuccin.frappe.yellow} ;;
        1[0-9]) icon="󰁺"; color=${catppuccin.frappe.peach} ;;
        *)      icon="󰂃"; color=${catppuccin.frappe.red} ;;
      esac

      # 如果正在充电，添加充电图标
      if ! [ -z "$charging" ]; then
        icon="$icon 󰚥"
        label_text="$battery_percent%"
      else
        label_text="$battery_percent%"
      fi

      sketchybar \
        --set $NAME \
          icon.color="$color" \
          icon="$icon" \
          label="$label_text"
    fi
  '';
  top-proc-sh = pkgs.writeShellScriptBin "top-proc.sh" ''
    TOPPROC=$(/bin/ps axo "%cpu,ucomm" | sort -nr | tail +1 | head -n1 | awk '{printf "%.0f%% %s\n", $1, $2}' | sed -e 's/com.apple.//g')
    CPUP=$(echo $TOPPROC | sed -nr 's/([^\%]+).*/\1/p')
    if [ $CPUP -gt 75 ]; then
      sketchybar -m --set $NAME label="$TOPPROC"
    else
      sketchybar -m --set $NAME label=""
    fi
  '';
in
{

  options = {
    heywoodlh.darwin.sketchybar.enable = mkOption {
      default = false;
      description = ''
        Enable heywoodlh nord-themed sketchybar.
      '';
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    system.defaults.NSGlobalDomain._HIHideMenuBar = true; # Disable menu bar
    services.sketchybar = {
      enable = true;
      config = # bash
        ''
          ############## BAR ##############
            sketchybar -m --bar \
              height=32 \
              position=top \
              padding_left=5 \
              padding_right=5 \
              color=${catppuccin.frappe.base} \
              shadow=off \
              sticky=on \
              topmost=off

          ############## GLOBAL DEFAULTS ##############
            sketchybar -m --default \
              updates=when_shown \
              drawing=on \
              icon.font="Hack Nerd Font Mono:Bold:18.0" \
              icon.color=${catppuccin.frappe.text} \
              label.font="Hack Nerd Font Mono:Bold:12.0" \
              label.color=${catppuccin.frappe.text}

          ############## SPACE DEFAULTS ##############
            sketchybar -m --default \
              label.padding_left=5 \
              label.padding_right=2 \
              icon.padding_left=8 \
              label.padding_right=8

          ############## PRIMARY DISPLAY SPACES ##############
            # APPLE ICON
            sketchybar -m --add item apple left \
              --set apple icon= \
              --set apple icon.font="Hack Nerd Font Mono:Regular:20.0" \
              --set apple label.padding_right=0 \

            # SETUP SPACES WITH NUMBERS AND ICONS
            ${lib.getExe spaces-sh}

          ############## ITEM DEFAULTS ###############
            sketchybar -m --default \
              label.padding_left=2 \
              icon.padding_right=2 \
              icon.padding_left=6 \
              label.padding_right=6

          ############## RIGHT ITEMS ##############
            # DATE TIME
            sketchybar -m --add item date_time right \
              --set date_time icon= \
              --set date_time icon.padding_left=8 \
              --set date_time icon.padding_right=0 \
              --set date_time label.padding_right=9 \
              --set date_time label.padding_left=6 \
              --set date_time label.color=${catppuccin.frappe.text} \
              --set date_time update_freq=20 \
              --set date_time background.color=${catppuccin.frappe.surface1} \
              --set date_time background.height=21 \
              --set date_time background.padding_right=12 \
              --set date_time script="${date-time-sh}/bin/date-time.sh" \

            # Battery STATUS
            sketchybar -m --add item battery right \
              --set battery icon.font="Hack Nerd Font Mono:Bold:10.0" \
              --set battery icon.padding_left=8 \
              --set battery icon.padding_right=8 \
              --set battery label.padding_right=8 \
              --set battery label.padding_left=0 \
              --set battery label.color=${catppuccin.frappe.text} \
              --set battery background.color=${catppuccin.frappe.surface1} \
              --set battery background.height=21 \
              --set battery background.padding_right=7 \
              --set battery update_freq=10 \
              --set battery script="${battery-sh}/bin/battery.sh" \

            # RAM USAGE
            sketchybar -m --add item topmem right \
              --set topmem icon= \
              --set topmem icon.padding_left=8 \
              --set topmem icon.padding_right=0 \
              --set topmem label.padding_right=8 \
              --set topmem label.padding_left=6 \
              --set topmem label.color=${catppuccin.frappe.text} \
              --set topmem background.color=${catppuccin.frappe.surface1} \
              --set topmem background.height=21 \
              --set topmem background.padding_right=7 \
              --set topmem update_freq=2 \
              --set topmem script="${top-mem-sh}/bin/top-mem.sh" \

            # CPU USAGE
            sketchybar -m --add item cpu_percent right \
              --set cpu_percent icon= \
              --set cpu_percent icon.padding_left=8 \
              --set cpu_percent icon.padding_right=0 \
              --set cpu_percent label.padding_right=8 \
              --set cpu_percent label.padding_left=6 \
              --set cpu_percent label.color=${catppuccin.frappe.text} \
              --set cpu_percent background.color=${catppuccin.frappe.surface1} \
              --set cpu_percent background.height=21 \
              --set cpu_percent background.padding_right=7 \
              --set cpu_percent update_freq=2 \
              --set cpu_percent script="${cpu-sh}/bin/cpu.sh" \

            # CAFFEINE
            sketchybar -m --add item caffeine right \
              --set caffeine icon.padding_left=8 \
              --set caffeine icon.padding_right=0 \
              --set caffeine label.padding_right=0 \
              --set caffeine label.padding_left=6 \
              --set caffeine label.color=${catppuccin.frappe.text} \
              --set caffeine background.color=${catppuccin.frappe.surface1} \
              --set caffeine background.height=21 \
              --set caffeine background.padding_right=7 \
              --set caffeine script="${caffeine-sh}/bin/caffeine.sh" \
              --set caffeine click_script="${caffeine-click-sh}/bin/caffeine-click.sh" \

            # TOP PROCESS
            sketchybar -m --add item topproc right \
              --set topproc drawing=on \
              --set topproc label.padding_right=10 \
              --set topproc update_freq=15 \
              --set topproc script="${top-proc-sh}/bin/top-proc.sh"

          ###################### CENTER ITEMS ###################
            sketchybar   --add item               mode_indicator center \
               --set mode_indicator     drawing=off \
                                        label.color=${catppuccin.frappe.surface1} \
                                        label.font="SF Pro:Bold:14.0" \
                                        background.padding_left=15 \
                                        background.padding_right=15

          ############## FINALIZING THE SETUP ##############
          sketchybar -m --update

          echo "sketchybar configuration loaded.."
        '';
    };
  };
}
