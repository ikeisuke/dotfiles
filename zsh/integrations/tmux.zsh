# tmux integration

# Auto-attach to tmux session (optional)
# Uncomment to automatically start/attach to tmux on shell start

# Standard tmux auto-attach
# if command -v tmux >/dev/null 2>&1; then
#   # Don't nest tmux sessions
#   if [ -z "$TMUX" ]; then
#     # Don't auto-attach in VS Code or other integrated terminals
#     case "$TERM_PROGRAM" in
#       vscode) ;;
#       *)
#         # Attach to 'main' session or create it
#         tmux attach -t main || tmux new -s main
#         ;;
#     esac
#   fi
# fi

# Uncomment to automatically start tmux in iTerm2
# if command -v tmux >/dev/null 2>&1; then
#   if [ -z "$TMUX" ] && [ "$TERM_PROGRAM" = "iTerm.app" ]; then
#     tmux -CC attach -t main || tmux -CC new -s main
#   fi
# fi

# Aliases for convenience
if command -v tmux >/dev/null 2>&1; then
  # Standard tmux
  alias tm='tmux attach -t main || tmux new -s main'
  alias tl='tmux list-sessions'
  alias ta='tmux attach -t'
  alias tn='tmux new -s'
  alias tk='tmux kill-session -t'

  # iTerm2 integration
  if [ "$TERM_PROGRAM" = "iTerm.app" ]; then
    alias tmi='tmux -CC attach -t main || tmux -CC new -s main'
    alias tai='tmux -CC attach -t'
    alias tni='tmux -CC new -s'
  fi
fi
