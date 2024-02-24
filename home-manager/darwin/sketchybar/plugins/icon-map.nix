{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "sketchybar-plugins-icon-map";
  text =
    # bash
    ''
      case $@ in
      "FaceTime")
        icon_result=":face_time:"
        ;;
      "Messages" | "WeCom")
        icon_result=":messages:"
        ;;
      "Twitter")
        icon_result=":twitter:"
        ;;
      "Microsoft Edge")
        icon_result=":microsoft_edge:"
        ;;
      "VLC")
        icon_result=":vlc:"
        ;;
      "Notes")
        icon_result=":notes:"
        ;;
      "App Store")
        icon_result=":app_store:"
        ;;
      "Chromium" | "Google Chrome" | "Google Chrome Canary")
        icon_result=":google_chrome:"
        ;;
      "Color Picker")
        icon_result=":color_picker:"
        ;;
      "Microsoft Word")
        icon_result=":microsoft_word:"
        ;;
      "Microsoft Teams")
        icon_result=":microsoft_teams:"
        ;;
      "Neovide" | "MacVim" | "Vim" | "VimR")
        icon_result=":vim:"
        ;;
      "WeChat")
        icon_result=":wechat:"
        ;;
      "VMware Fusion")
        icon_result=":vmware_fusion:"
        ;;
      "Microsoft Excel")
        icon_result=":microsoft_excel:"
        ;;
      "Microsoft PowerPoint")
        icon_result=":microsoft_power_point:"
        ;;
      "Numbers")
        icon_result=":numbers:"
        ;;
      "Default")
        icon_result=":default:"
        ;;
      "Firefox Developer Edition" | "Firefox Nightly")
        icon_result=":firefox_developer_edition:"
        ;;
      "Notion")
        icon_result=":notion:"
        ;;
      "Calendar" | "Fantastical")
        icon_result=":calendar:"
        ;;
      "Android Studio")
        icon_result=":android_studio:"
        ;;
      "Xcode")
        icon_result=":xcode:"
        ;;
      "Slack")
        icon_result=":slack:"
        ;;
      "System Preferences" | "System Settings")
        icon_result=":gear:"
        ;;
      "Discord" | "Discord Canary" | "Discord PTB")
        icon_result=":discord:"
        ;;
      "Firefox")
        icon_result=":firefox:"
        ;;
      "Safari" | "Safari Technology Preview")
        icon_result=":safari:"
        ;;
      "Telegram")
        icon_result=":telegram:"
        ;;
      "Keynote")
        icon_result=":keynote:"
        ;;
      "Spotlight")
        icon_result=":spotlight:"
        ;;
      "Music")
        icon_result=":music:"
        ;;
      "Pages")
        icon_result=":pages:"
        ;;
      # TODO: find a good icon
      "Omnivore")
        icon_result=":notes:"
        ;;
      "Dash")
        icon_result=":book:"
        ;;
      "Logseq")
        icon_result=":logseq:"
        ;;
      "Reminders")
        icon_result=":reminders:"
        ;;
      "Preview" | "Skim" | "zathura")
        icon_result=":pdf:"
        ;;
      "Code" | "Code - Insiders")
        icon_result=":code:"
        ;;
      "VSCodium")
        icon_result=":vscodium:"
        ;;
      "Finder" | "ForkLift")
        icon_result=":finder:"
        ;;
      "Alacritty" | "Hyper" | "iTerm2" | "kitty" | "Terminal" | "WezTerm")
        icon_result=":terminal:"
        ;;
      "KeePassXC")
        icon_result=":kee_pass_x_c:"
        ;;
      *)
        icon_result=":default:"
        ;;
      esac
      echo $icon_result
    '';
}
