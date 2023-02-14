{ pkgs }:

with pkgs;

writeShellScriptBin "cleaner" ''
  if [ -n "$FIFO_UEBERZUG" ]; then
    printf '{"action": "remove", "identifier": "PREVIEW"}\n' > "$FIFO_UEBERZUG"
  fi
''
