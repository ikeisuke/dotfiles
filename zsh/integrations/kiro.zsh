# kiro terminal integration
if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro &>/dev/null; then
  . "$(kiro --locate-shell-integration-path zsh)"
fi
