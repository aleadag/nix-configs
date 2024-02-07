{ pkgs, config, ... }:

pkgs.writeShellScriptBin "add-to-instapaper" ''
  # Add a URL to Instapaper.
  #
  # Usage:
  #
  # $ add-to-instapaper <url> <title>
  # https://newsboat.org/releases/2.25/docs/newsboat.html#_bookmarking

  curl "https://www.instapaper.com/api/add" --data-urlencode
  "username=${config.home.sessionVariables.INST_USERNAME}" --data-urlencode
  "password=${config.home.sessionVariables.INST_PASSWORD}" --data-urlencode "url=$1" --data-urlencode "title=$2" > /dev/null &
''
