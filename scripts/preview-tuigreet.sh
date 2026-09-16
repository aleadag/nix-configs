#!/usr/bin/env bash
set -euo pipefail

THEME="border=blue;title=magenta;greet=white;prompt=white;text=gray;input=gray;action=blue;button=magenta;time=gray;container=black"

show_palette() {
  echo -e "\n=== Active 16-Color TTY Palette ==="
  for i in {0..15}; do
    printf "\e[48;5;%dm  %2d  \e[0m" "$i" "$i"
    if (((i + 1) % 8 == 0)); then
      echo
    fi
  done
  echo
}

apply_catppuccin_tty_palette() {
  echo "Applying official Catppuccin Frappé 16-color palette to current terminal/TTY..."
  # Escape sequence \e]P<index><hex> sets Linux VT palette registers 0-15 matching catppuccin/tty
  printf "\e]P0303446\e]P1e78284\e]P2a6d189\e]P3e5c890\e]P48caaee\e]P5f4b8e4\e]P681c8be\e]P7b5bfe2\e]P8626880\e]P9e78284\e]Paa6d189\e]Pbe5c890\e]Pc8caaee\e]Pdf4b8e4\e]Pe81c8be\e]Pfa5adce"
  clear || true
  echo "Official Catppuccin Frappé palette applied to this virtual console session!"
  show_palette
}

preview_tuigreet() {
  echo "Launching tuigreet in mock mode with Catppuccin Frappé theme..."
  echo "Press [Esc] or [Ctrl+C] to exit."
  sleep 1

  nix run nixpkgs#tuigreet -- --mock --time --theme "$THEME"
}

run_menu() {
  while true; do
    clear || true
    echo "=========================================================="
    echo "           tuigreet Theme Preview & Test Helper           "
    echo "=========================================================="
    echo " Tip: To switch back to your desktop from a TTY, press:   "
    echo "      Ctrl + Alt + F1  (or Ctrl + Alt + F2)               "
    echo "=========================================================="
    echo "1) Preview tuigreet (Catppuccin Frappé theme)"
    echo "2) Apply Catppuccin Frappé palette live to current TTY"
    echo "3) Display current 16-color TTY palette"
    echo "4) Exit"
    echo
    read -r -p "Select an option [1-4]: " choice

    case "$choice" in
    1)
      preview_tuigreet
      ;;
    2)
      apply_catppuccin_tty_palette
      read -r -p "Press Enter to return to menu..." _
      ;;
    3)
      show_palette
      read -r -p "Press Enter to return to menu..." _
      ;;
    4 | q | Q)
      break
      ;;
    *)
      echo "Invalid option."
      sleep 1
      ;;
    esac
  done
}

case "${1:-}" in
apply | apply-palette)
  apply_catppuccin_tty_palette
  ;;
preview | frappe)
  preview_tuigreet
  ;;
palette)
  show_palette
  ;;
menu | "")
  run_menu
  ;;
*)
  run_menu
  ;;
esac
