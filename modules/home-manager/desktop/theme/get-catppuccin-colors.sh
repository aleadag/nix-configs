#! /usr/bin/env nix-shell
#! nix-shell -i bash -p curl jq

set -euo pipefail

# Takes a raw link to the base16 YAML file and converts it to JSON
# Example:
# $ ./get-catppuccin-colors.sh https://raw.githubusercontent.com/catppuccin/palette/e44233ceae6809d50cba3c0c95332cc87ffff022/palette.json | tee ./colors.json

curl -s "$1" | \
    jq 'map_values(.colors | map_values(.hex))' 
