# Auto-recompile zsh files when they're newer than compiled versions
# Uses zrecompile to only recompile when source is newer than .zwc
# Skips if last check was within the current shell session day

autoload -U zrecompile

# Only run full recompile check once per day (use marker file)
local _zc_marker="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompile-marker"
local _zc_today=$(date +%Y%m%d)

if [[ -f "$_zc_marker" ]] && [[ "$(< "$_zc_marker")" == "$_zc_today" ]]; then
  return
fi

# Recompile main config files
zrecompile -p -R ~/.zshenv -- -M ~/.zshenv.zwc ~/.zshenv
zrecompile -p -R ~/.zprofile -- -M ~/.zprofile.zwc ~/.zprofile
zrecompile -p -R ~/.zshrc -- -M ~/.zshrc.zwc ~/.zshrc

# Recompile all dotfiles modules (quietly)
for file in ${DOTFILES_DIR}/**/*.zsh(N); do
  zrecompile -q -p "$file"
done

# Update marker
mkdir -p "${_zc_marker:h}"
echo "$_zc_today" > "$_zc_marker"
