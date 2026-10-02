{
  pkgs,
  package,
  configFile,
  secretFile,
}:
pkgs.writeShellApplication {
  name = "agent-steward";
  text = ''
    set +x
    unset TYPESAFE_API_KEY
    # History and help use neither the routing config nor the credential.
    case "''${1:-} ''${2:-}" in
      'router list'|'router show'|'router --help'|'router -h'|'--help '*|'-h '*)
        exec ${pkgs.lib.escapeShellArg "${package}/bin/agent-steward"} "$@"
        ;;
    esac
    # The credential path is escaped literal data, including shell-like syntax.
    # shellcheck disable=SC2016
    secret_file=${pkgs.lib.escapeShellArg (toString secretFile)}
    fail() {
      printf '%s\n' 'agent-steward: credential unavailable' >&2
      exit 1
    }
    if [[ "$secret_file" == *%r* ]]; then
      ${
        if pkgs.stdenv.hostPlatform.isDarwin then
          ''
            if ! runtime_dir="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"; then
              fail
            fi
          ''
        else
          ''
            runtime_dir="''${XDG_RUNTIME_DIR:-}"
          ''
      }
      if [[ "$runtime_dir" != /* ]]; then
        fail
      fi
      # Substitute as literal data, including ampersands and percent markers.
      remaining="$secret_file"
      resolved=""
      while [[ "$remaining" == *%r* ]]; do
        resolved+="''${remaining%%\%r*}$runtime_dir"
        remaining="''${remaining#*\%r}"
      done
      secret_file="$resolved$remaining"
    fi
    if [[ ! -f "$secret_file" || ! -r "$secret_file" ]]; then
      fail
    fi
    # Bash command substitution drops NUL bytes, so reject them before reading the key.
    if IFS= read -r -d $'\0' _ 2>/dev/null < "$secret_file"; then
      fail
    fi
    if ! TYPESAFE_API_KEY="$(${pkgs.coreutils}/bin/cat -- "$secret_file" 2>/dev/null)"; then
      fail
    fi
    if [[ ! "$TYPESAFE_API_KEY" =~ [^[:space:]] ]]; then
      fail
    fi
    export TYPESAFE_API_KEY
    # The config path is escaped literal data, including shell-like syntax.
    # shellcheck disable=SC2016
    exec ${pkgs.lib.escapeShellArg "${package}/bin/agent-steward"} \
      --config ${pkgs.lib.escapeShellArg (toString configFile)} "$@"
  '';
}
