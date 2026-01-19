#!/usr/bin/env bash
# statusline.sh - Claude Code status line that mimics starship prompt
#
# This script generates a status line for Claude Code that matches the
# starship configuration with Catppuccin Mocha colors and powerline separators.

# Individual operations have their own timeouts for better control
# No global timeout wrapper needed

# Enable timing if DEBUG_TIMING is set
if [[ ${DEBUG_TIMING:-} == "1" ]]; then
  exec 3>&2 # Save stderr
  TIMING_LOG="/tmp/statusline_timing_$$"
  : >"$TIMING_LOG"

  time_point() {
    local label="$1"
    echo "$(date +%s%3N) $label" >>"$TIMING_LOG"
  }

  finish_timing() {
    if [[ -f $TIMING_LOG ]]; then
      awk 'NR==1{start=$1} {printf "[%4dms] %s\n", $1-start, substr($0, index($0, $2))}' "$TIMING_LOG" >&3
      rm -f "$TIMING_LOG"
    fi
  }
  trap finish_timing EXIT
else
  time_point() { :; }
  finish_timing() { :; }
fi

time_point "START"

# Helper function to get file modification time (works on both macOS and Linux)
# Define early as it's needed for cache checks
get_file_mtime() {
  local file="$1"
  if [[ ! -f $file ]]; then
    echo "0"
    return
  fi

  # GNU stat
  stat -c %Y "$file" 2>/dev/null || echo "0"
}

# Read JSON input FIRST to check cache
time_point "before_read_stdin"
input=$(cat)
time_point "after_read_stdin"

# Quick parse to get cache key (directory is main variable)
time_point "before_cache_check"
CURRENT_DIR_FOR_CACHE=$(echo "$input" | jq -r '.workspace.project_dir // .workspace.current_dir // .cwd // "~"' 2>/dev/null || echo "~")
CACHE_KEY="$(echo -n "$CURRENT_DIR_FOR_CACHE" | md5sum | cut -d' ' -f1)"

# Use RAM-based /dev/shm to avoid SSD wear from frequent cache checks
# Allow override for testing
CACHE_DIR="${CLAUDE_STATUSLINE_CACHE_DIR:-/dev/shm}"
CACHE_FILE="${CACHE_DIR}/claude_statusline_${CACHE_KEY}"

# Configurable cache duration (default 20 seconds)
# This reduces computation from 180/minute to just 3/minute
CACHE_DURATION="${CLAUDE_STATUSLINE_CACHE_SECONDS:-20}"

# Check data cache (valid for 5 seconds)
USE_CACHE=0
if [[ -f $CACHE_FILE ]]; then
  age=$(($(date +%s) - $(get_file_mtime "$CACHE_FILE")))
  if [[ $age -lt $CACHE_DURATION ]]; then
    time_point "cache_hit"
    # Load cached data
    # shellcheck source=/dev/null
    source "$CACHE_FILE"
    USE_CACHE=1
  fi
fi

if [[ $USE_CACHE -eq 0 ]]; then
  time_point "cache_miss"
fi

# ============================================================================
# CATPPUCCIN MOCHA COLORS - True color (24-bit) support
# ============================================================================

# Using true color escape sequences for exact Catppuccin Mocha colors
LAVENDER_BG="\033[48;2;180;190;254m" # #b4befe
LAVENDER_FG="\033[38;2;180;190;254m"
GREEN_BG="\033[48;2;166;227;161m" # #a6e3a1
GREEN_FG="\033[38;2;166;227;161m"
SKY_BG="\033[48;2;137;220;235m" # #89dceb
SKY_FG="\033[38;2;137;220;235m"
YELLOW_BG="\033[48;2;249;226;175m" # #f9e2af (Catppuccin Mocha yellow)
YELLOW_FG="\033[38;2;249;226;175m"
PEACH_BG="\033[48;2;250;179;135m" # #fab387
PEACH_FG="\033[38;2;250;179;135m"
RED_BG="\033[48;2;243;139;168m" # #f38ba8 (Catppuccin Mocha red)
RED_FG="\033[38;2;243;139;168m"
BASE_FG="\033[38;2;30;30;46m" # #1e1e2e (dark text on colored backgrounds)
NC="\033[0m"                  # No Color / Reset

# Powerline characters
LEFT_CHEVRON=""
LEFT_CURVE=""
RIGHT_CURVE=""

# Icons for different sections (customize as needed)
CONTEXT_ICON=" "
MODEL_ICONS="󰚩󱚝󱚟󱚡󱚣󱚥"

# ============================================================================
# MAIN LOGIC
# ============================================================================

# Only parse JSON if we don't have cached data
if [[ $USE_CACHE -eq 0 ]]; then
  # Parse ALL JSON values at once (single jq invocation for performance)
  # Input already read above for cache check
  time_point "before_jq_parse"
  json_values=$(echo "$input" | timeout 0.1s jq -r '
      (.model.display_name // "Claude") + "|" +
      (.workspace.project_dir // .workspace.current_dir // .cwd // "~") + "|" +
      (.transcript_path // "")
  ' 2>/dev/null || echo "Claude|~|")
  time_point "after_jq_parse"

  # Split the parsed values
  IFS='|' read -r MODEL_DISPLAY CURRENT_DIR TRANSCRIPT_PATH <<<"$json_values"
fi

# Select a random icon from MODEL_ICONS
ICON_COUNT=${#MODEL_ICONS}
RANDOM_INDEX=$((RANDOM % ICON_COUNT))
MODEL_ICON="${MODEL_ICONS:RANDOM_INDEX:1} "

# We'll handle transcript search later with other cached operations
# But we need to define functions here so they're available in subshells

# Get token metrics if transcript is available (accurate version)
get_token_metrics() {
  local transcript="$1"
  if [[ -z $transcript ]] || [[ ! -f $transcript ]]; then
    echo "0|0|0|0"
    return
  fi

  # Read the full transcript for accurate token counts
  # Only takes ~7ms even for large files, worth it for accuracy
  local result
  # shellcheck disable=SC2016  # Single quotes are correct for jq script
  result=$(timeout 0.2s jq -s -r '
            map(select(.message.usage != null)) |
            if length == 0 then
                "0|0|0|0"
            else
                (map(.message.usage.input_tokens // 0) | add) as $input |
                (map(.message.usage.output_tokens // 0) | add) as $output |
                (map(.message.usage.cache_read_input_tokens // 0) | add) as $cached |
                (last | .message.usage |
                    ((.input_tokens // 0) +
                     (.cache_read_input_tokens // 0) +
                     (.cache_creation_input_tokens // 0))) as $context |
                "\($input)|\($output)|\($cached)|\($context)"
            end
        ' <"$transcript" 2>/dev/null)

  if [[ -n $result ]]; then
    echo "$result"
  else
    echo "0|0|0|0"
  fi
}

# Truncate text to a maximum length with ellipsis
truncate_text() {
  local text="$1"
  local max_length="$2"

  # Count actual display width (handles UTF-8)
  local length
  length=$(echo -n "$text" | wc -m | tr -d ' ')

  if [[ $length -le $max_length ]]; then
    echo "$text"
  else
    # Leave room for ellipsis (…)
    local truncate_at=$((max_length - 1))
    # Use printf to properly handle UTF-8 truncation
    local truncated
    truncated=$(echo "$text" | cut -c1-${truncate_at})
    echo "${truncated}…"
  fi
}

# Note: We use simple caching with /dev/shm (RAM) to avoid disk I/O
# All expensive operations are computed once and cached for CACHE_DURATION seconds

# transcript_path is provided directly in the JSON input, no need to search for it!

# Skip expensive operations if we have cached data
if [[ $USE_CACHE -eq 0 ]]; then

  # Compute all data directly (no complex parallel operations or individual caches)
  time_point "before_compute"

  # Get token metrics if transcript exists
  if [[ -n $TRANSCRIPT_PATH ]] && [[ -f $TRANSCRIPT_PATH ]]; then
    IFS='|' read -r INPUT_TOKENS OUTPUT_TOKENS _ CONTEXT_LENGTH <<<"$(get_token_metrics "$TRANSCRIPT_PATH")"
  else
    INPUT_TOKENS=0
    OUTPUT_TOKENS=0
    CONTEXT_LENGTH=0
  fi

  time_point "after_compute"

  # Save all data to cache file
  cat >"$CACHE_FILE" <<EOF
# Cached statusline data
MODEL_DISPLAY="$MODEL_DISPLAY"
CURRENT_DIR="$CURRENT_DIR"
TRANSCRIPT_PATH="$TRANSCRIPT_PATH"
INPUT_TOKENS="$INPUT_TOKENS"
OUTPUT_TOKENS="$OUTPUT_TOKENS"
CONTEXT_LENGTH="$CONTEXT_LENGTH"
EOF

fi # End of cache miss block
# Format token count for display
format_tokens() {
  local count=$1
  if [[ $count -ge 1000000 ]]; then
    printf "%.1fM" "$(awk "BEGIN {printf \"%.1f\", $count / 1000000}")"
  elif [[ $count -ge 1000 ]]; then
    printf "%.1fk" "$(awk "BEGIN {printf \"%.1f\", $count / 1000}")"
  else
    echo "$count"
  fi
}

# ============================================================================
# BUILD STATUS LINE
# ============================================================================

# Token metrics already retrieved in parallel section above

# Debug context length
if [[ ${STATUSLINE_DEBUG:-} == "1" ]]; then
  >&2 echo "DEBUG: CONTEXT_LENGTH=$CONTEXT_LENGTH, INPUT_TOKENS=$INPUT_TOKENS, TRANSCRIPT_PATH=$TRANSCRIPT_PATH"
fi

# Build statusline
STATUS_LINE=""

# Set reasonable model name truncation length
MODEL_MAX_LEN=25

# Build context and model sections

# Create context percentage section (replacing directory)
if [[ $CONTEXT_LENGTH -gt 0 ]]; then
  # Calculate percentage
  CONTEXT_PERCENTAGE=$(awk "BEGIN {printf \"%.0f\", $CONTEXT_LENGTH * 100 / 160000}")
  if [[ $CONTEXT_PERCENTAGE -gt 100 ]]; then
    CONTEXT_PERCENTAGE=100
  fi

  # Choose background color based on percentage
  CONTEXT_BG="${GREEN_BG}"
  CONTEXT_FG="${GREEN_FG}"
  if [[ $CONTEXT_PERCENTAGE -ge 80 ]]; then
    CONTEXT_BG="${RED_BG}"
    CONTEXT_FG="${RED_FG}"
  elif [[ $CONTEXT_PERCENTAGE -ge 60 ]]; then
    CONTEXT_BG="${PEACH_BG}"
    CONTEXT_FG="${PEACH_FG}"
  elif [[ $CONTEXT_PERCENTAGE -ge 40 ]]; then
    CONTEXT_BG="${YELLOW_BG}"
    CONTEXT_FG="${YELLOW_FG}"
  fi

  # Start with context percentage section (replacing directory)
  STATUS_LINE="${NC}${CONTEXT_FG}${LEFT_CURVE}${CONTEXT_BG}${BASE_FG} ${CONTEXT_ICON}${CONTEXT_PERCENTAGE}% ${NC}"
else
  # No context data, use a simple placeholder
  STATUS_LINE="${NC}${LAVENDER_FG}${LEFT_CURVE}${LAVENDER_BG}${BASE_FG} ${CONTEXT_ICON}-- ${NC}"
fi

# Add LEFT_CHEVRON between context and model sections
STATUS_LINE="${STATUS_LINE}${SKY_BG}${CONTEXT_FG}${LEFT_CHEVRON}${NC}"

# Show model name and token usage
# Truncate model name using dynamic length
MODEL_DISPLAY_TRUNCATED=$(truncate_text "$MODEL_DISPLAY" $MODEL_MAX_LEN)

TOKEN_INFO=""
if [[ $INPUT_TOKENS -gt 0 ]] || [[ $OUTPUT_TOKENS -gt 0 ]]; then
  TOKEN_INFO=" ${MODEL_ICON:-}${MODEL_DISPLAY_TRUNCATED} ↑$(format_tokens "$INPUT_TOKENS") ↓$(format_tokens "$OUTPUT_TOKENS")"
else
  TOKEN_INFO=" ${MODEL_ICON:-}${MODEL_DISPLAY_TRUNCATED}"
fi
STATUS_LINE="${STATUS_LINE}${SKY_BG}${BASE_FG}${TOKEN_INFO} ${NC}"

# End the model section with RIGHT_CURVE
STATUS_LINE="${STATUS_LINE}${SKY_FG}${RIGHT_CURVE}${NC}"

# Output the statusline (no newline - statusline should be exact width)
time_point "before_output"
printf '%b' "$STATUS_LINE"
time_point "after_output"
