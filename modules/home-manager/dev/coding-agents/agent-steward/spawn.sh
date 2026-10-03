#!/usr/bin/env bash
set -euo pipefail
set +x
# Working from: agent-steward/.internal/sdd/2026-10-02-agent-to-agent-routing/task-4-amendment.md
unset TYPESAFE_API_KEY
if [[ ${1:-} == --help || ${1:-} == -h ]]; then
	printf '%s\n' 'Usage: steward-spawn --target-pane <id> [--direction <right|down>] --name <unique> --cwd <absolute-dir> -- <instruction>'
	exit 0
fi
target=""
direction=""
name=""
cwd=""
separator=false
while (($#)); do
	case "$1" in
	--target-pane | --direction | --name | --cwd)
		(($# >= 2)) || exit 1
		case "$1" in
		--target-pane) target="$2" ;;
		--direction) direction="$2" ;;
		--name) name="$2" ;;
		--cwd) cwd="$2" ;;
		esac
		shift 2
		;;
	--)
		separator=true
		shift
		break
		;;
	*) exit 1 ;;
	esac
done
[[ "$separator" == true && $# == 1 ]] || exit 1
instruction="$1"
[[ -n "$target" && -n "$name" && -n "$instruction" ]] || exit 1
[[ "$cwd" == /* && -d "$cwd" ]] || exit 1
steward=$(type -P agent-steward) || exit 1
herdr=$(type -P herdr) || exit 1
[[ "$steward" == /* && -x "$steward" && "$herdr" == /* && -x "$herdr" ]] || exit 1
if [[ -z $direction ]]; then
	layout_out=$("$herdr" pane layout --pane "$target" | python3 -c 'import json,sys
raw=json.load(sys.stdin)
block=raw.get("result", raw)
layout=block.get("layout", block)
best_id,best_area,w,h="",-1,0,0
for pane in layout.get("panes") or []:
 rect=pane.get("rect") or {}
 pw,ph=int(rect.get("width") or 0), int(rect.get("height") or 0)
 area=pw*ph
 if area>best_area and pane.get("pane_id"):
  best_id,best_area,w,h=pane.get("pane_id"),area,pw,ph
if not best_id:
 sys.exit(1)
print(best_id)
# Terminal cells are roughly twice as tall as they are wide.
print("down" if 2*h>=w else "right")
') || exit 1
	target=$(printf '%s\n' "$layout_out" | sed -n '1p')
	direction=$(printf '%s\n' "$layout_out" | sed -n '2p')
fi
[[ $direction == right || $direction == down ]] || exit 1
umask 077
launch_dir=$(mktemp -d)
launch_script="$launch_dir/start.sh"
{
	printf '#!/usr/bin/env bash\nset +x\ntrap '\'''\'' TSTP\n'
	printf 'cd -- %q || exit 1\n' "$cwd"
	printf 'exec %q router start -- %q\n' "$steward" "$instruction"
} >"$launch_script"
chmod 0600 "$launch_script"
# Keep scripts even on failure: opening may have already launched the child.
open_status=0
opened=$(
	"$herdr" plugin pane open --plugin agent-steward-launcher --entrypoint argv \
		--placement split --target-pane "$target" --direction "$direction" \
		--cwd "$cwd" --env "PI_HERDR_LAUNCH_SCRIPT=$launch_script" --no-focus
) || open_status=$?
if [[ $open_status -eq 0 ]]; then
	pane_id=$(printf '%s' "$opened" | python3 -c 'import json,sys
try:
 print(json.load(sys.stdin)["result"]["plugin_pane"]["pane"]["pane_id"])
except Exception:
 sys.exit(1)
') || pane_id=""
	if [[ -n $pane_id ]]; then
		"$herdr" pane rename "$pane_id" "$name" || true
	fi
fi
printf '%s\n' "$name"
exit "$open_status"
