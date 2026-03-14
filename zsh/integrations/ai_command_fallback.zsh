# AI fallback for unknown commands
# If an input looks like natural Japanese text and the command does not exist,
# forward the text to a configurable AI CLI instead of executing it.

typeset -g AI_FALLBACK_TARGET="${AI_FALLBACK_TARGET:-codex}"
typeset -g AI_JP_RATIO_THRESHOLD="${AI_JP_RATIO_THRESHOLD:-0.35}"
typeset -g AI_MIN_LEN="${AI_MIN_LEN:-6}"
typeset -g AI_FALLBACK_INTERACTIVE="${AI_FALLBACK_INTERACTIVE:-0}"

_ai_jp_len() {
  local s="$1"
  local jp_only

  if ! command -v perl >/dev/null 2>&1; then
    echo 0
    return 0
  fi

  jp_only=$(print -r -- "$s" | perl -CS -pe 's/[^\p{Hiragana}\p{Katakana}\p{Han}]//g')
  echo ${#jp_only}
}

_ai_should_send() {
  local input="$1"
  local total jp

  [[ -z "$input" ]] && return 1
  [[ "$input" == /* ]] && return 1

  total=${#input}
  (( total < AI_MIN_LEN )) && return 1

  jp=$(_ai_jp_len "$input")
  (( jp == 0 )) && return 1

  perl -e "exit(($jp / $total) >= $AI_JP_RATIO_THRESHOLD ? 0 : 1)"
}

_ai_send() {
  local msg="$1"
  local target="$AI_FALLBACK_TARGET"
  local -a cmd
  local use_interactive=0

  [[ "$AI_FALLBACK_INTERACTIVE" == "1" ]] && use_interactive=1

  case "$target" in
    codex)
      if (( use_interactive )); then
        cmd=(codex "$msg")
      else
        cmd=(codex exec --skip-git-repo-check "$msg")
      fi
      ;;
    claude)
      if (( use_interactive )); then
        cmd=(claude "$msg")
      else
        cmd=(claude --print --no-session-persistence "$msg")
      fi
      ;;
    kiro | kiro-cli)
      if (( use_interactive )); then
        cmd=(kiro-cli chat "$msg")
      else
        cmd=(kiro-cli chat --no-interactive "$msg")
      fi
      ;;
    kiro-cli-chat)
      if (( use_interactive )); then
        cmd=(kiro-cli-chat chat "$msg")
      else
        cmd=(kiro-cli-chat chat --no-interactive "$msg")
      fi
      ;;
    *)
      cmd=("$target" "$msg")
      ;;
  esac

  if ! command -v "${cmd[1]}" >/dev/null 2>&1; then
    print -u2 "ai-fallback: '$target' is not available (set AI_FALLBACK_TARGET)."
    return 1
  fi

  echo ""
  echo "AIへ送信 (${target}):"
  echo "--------------------------------"
  echo "$msg"
  echo "--------------------------------"
  echo ""

  if (( use_interactive )); then
    "${cmd[@]}" </dev/tty >/dev/tty 2>/dev/tty
  else
    "${cmd[@]}"
  fi
}

# Keep existing command_not_found behavior if another module already defined it.
if typeset -f command_not_found_handler >/dev/null 2>&1; then
  functions -c command_not_found_handler _ai_prev_command_not_found_handler
fi

command_not_found_handler() {
  local cmd="$1"
  local line
  shift
  line="$cmd"
  (( $# > 0 )) && line+=" ${*:q}"

  if _ai_should_send "$line"; then
    _ai_send "$line"
    return $?
  fi

  if typeset -f _ai_prev_command_not_found_handler >/dev/null 2>&1; then
    _ai_prev_command_not_found_handler "$cmd" "$@"
    return $?
  fi

  print -u2 "zsh: command not found: $cmd"
  return 127
}
