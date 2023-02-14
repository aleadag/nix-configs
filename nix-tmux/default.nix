{ pkgs, lib, ... }:
let
  myTmuxPlugins = import ./plugins.nix { inherit pkgs lib; };
in {
  programs.tmux = {
    enable = true;
    terminal = "screen-256color";
    keyMode = "emacs";
    historyLimit = 20000;
    escapeTime = 0;
    # Change prefix key to C-a, easier to type, same to "screen"
    prefix = "C-a";
    baseIndex = 1;
    # Enable mouse support
    mouse = true;
    aggressiveResize = true;
    sensibleOnTop = false;
    plugins = with pkgs; [
      {
        plugin = myTmuxPlugins.battery;
        extraConfig = ''
          # 必须在plugin加载之前设置status bar!!!!
          # 故而主题的配置也提上来。必须在第一个plugin里设置！！
          # =====================================
          # ===           Theme               ===
          # =====================================

          # Feel free to NOT use this variables at all (remove, rename)
          # this are named colors, just for convenience
          color_orange="colour166" # 208, 166
          color_purple="colour134" # 135, 134
          color_green="colour076" # 070
          color_blue="colour39"
          color_yellow="colour220"
          color_red="colour160"
          color_black="colour232"
          color_white="white" # 015

          # This is a theme CONTRACT, you are required to define variables below
          # Change values, but not remove/rename variables itself
          color_dark="$color_black"
          color_light="$color_white"
          color_session_text="$color_blue"
          color_status_text="colour245"
          color_main="$color_orange"
          color_secondary="$color_purple"
          color_level_ok="$color_green"
          color_level_warn="$color_yellow"
          color_level_stress="$color_red"
          color_window_off_indicator="colour088"
          color_window_off_status_bg="colour238"
          color_window_off_status_current_bg="colour254"

          # Configure tmux-battery widget colors
          set -g @batt_color_full_charge "#[fg=$color_level_ok]"
          set -g @batt_color_high_charge "#[fg=$color_level_ok]"
          set -g @batt_color_medium_charge "#[fg=$color_level_warn]"
          set -g @batt_color_low_charge "#[fg=$color_level_stress]"

          # define widgets we're going to use in status bar
          # note, that this is not the complete list, some of them are loaded from plugins
          wg_session="#[fg=$color_session_text] #S #[default]"
          wg_battery="#{battery_status_fg} #{battery_icon} #{battery_percentage}"
          wg_date="#[fg=$color_secondary]%h %d %H:%M#[default]"
          wg_user_host="#[fg=$color_secondary]#(whoami)#[default]@#H"
          wg_is_zoomed="#[fg=$color_dark,bg=$color_secondary]#{?window_zoomed_flag,[Z],}#[default]"
          # TODO: highlighted for nested local session as well
          wg_is_keys_off="#[fg=$color_light,bg=$color_window_off_indicator]#([ $(tmux show-option -qv key-table) = 'off' ] && echo 'OFF')#[default]"

          set -g status-left "$wg_session"
          set -g status-right "#{prefix_highlight} $wg_is_keys_off $wg_is_zoomed #{sysstat_cpu} | #{sysstat_mem} | #{sysstat_loadavg} | $wg_date $wg_battery #{online_status}"
        '';
      }
      tmuxPlugins.copycat
      {
        plugin = tmuxPlugins.online-status;
        extraConfig = ''
          # online and offline icon for tmux-online-status
          set -g @online_icon "#[fg=$color_level_ok]●#[default]"
          set -g @offline_icon "#[fg=$color_level_stress]●#[default]"
        '';
      }
      {
        plugin = tmuxPlugins.open;
        extraConfig = ''
          set -g @open-S 'https://www.google.com/search?q='
          set -g @route_to_ping 'www.bing.com'
        '';
      }
      {
        plugin = tmuxPlugins.sysstat;
        extraConfig = ''
          # Configure view templates for tmux-plugin-sysstat "MEM" and "CPU" widget
          set -g @sysstat_mem_view_tmpl 'MEM:#[fg=#{mem.color}]#{mem.pused}#[default] #{mem.used}'

          # Configure colors for tmux-plugin-sysstat "MEM" and "CPU" widget
          set -g @sysstat_cpu_color_low "$color_level_ok"
          set -g @sysstat_cpu_color_medium "$color_level_warn"
          set -g @sysstat_cpu_color_stress "$color_level_stress"

          set -g @sysstat_mem_color_low "$color_level_ok"
          set -g @sysstat_mem_color_medium "$color_level_warn"
          set -g @sysstat_mem_color_stress "$color_level_stress"

          set -g @sysstat_swap_color_low "$color_level_ok"
          set -g @sysstat_swap_color_medium "$color_level_warn"
          set -g @sysstat_swap_color_stress "$color_level_stress"
        '';
      }
      {
        plugin = tmuxPlugins.prefix-highlight;
        extraConfig = ''
          # Configure tmux-prefix-highlight colors
          set -g @prefix_highlight_output_prefix '['
          set -g @prefix_highlight_output_suffix ']'
          set -g @prefix_highlight_fg "$color_dark"
          set -g @prefix_highlight_bg "$color_secondary"
          set -g @prefix_highlight_show_copy_mode 'on'
          set -g @prefix_highlight_copy_mode_attr "fg=$color_dark,bg=$color_secondary"
        '';
      }
      {
        plugin = tmuxPlugins.sidebar;
        extraConfig = ''
          set -g @sidebar-tree 't'
          set -g @sidebar-tree-focus 'T'
          set -g @sidebar-tree-command 'tree -C'
        '';
      }
    ];
    extraConfig = lib.strings.fileContents ./tmux.conf;
  };

  xdg.configFile = {
    "tmux/renew_env.sh".source = ./renew_env.sh;
    "tmux/tmux.remote.conf".source = ./tmux.remote.conf;
    "tmux/yank.sh".source = ./yank.sh;
  };
}
