# PATH management
# Ensure uniqueness in path arrays
typeset -U path PATH fpath

# Helper functions for path management
path_prepend() {
  for dir in "$@"; do
    [[ -d "$dir" ]] && path=("$dir" $path)
  done
}

path_append() {
  for dir in "$@"; do
    [[ -d "$dir" ]] && path+=("$dir")
  done
}
