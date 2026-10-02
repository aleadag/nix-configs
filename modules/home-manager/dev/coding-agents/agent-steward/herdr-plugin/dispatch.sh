#!/usr/bin/env bash
set -u
launch_script="${PI_HERDR_LAUNCH_SCRIPT:-}"
if [[ -z "$launch_script" ]]; then
	echo "steward-argv dispatcher: PI_HERDR_LAUNCH_SCRIPT is unset or empty" >&2
	exit 64
fi
if [[ ! -r "$launch_script" ]]; then
	echo "steward-argv dispatcher: launch script is not readable" >&2
	exit 66
fi
exec bash "$launch_script"
