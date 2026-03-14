# Volta (Node.js version manager)
# Note: Volta requires $HOME/.volta (non-XDG); no official XDG support
export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
if [[ -d "$VOLTA_HOME" ]]; then
  path_prepend "$VOLTA_HOME/bin"
fi
