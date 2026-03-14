# Auto-recompile zsh files when they're newer than compiled versions
# Uses zrecompile to only recompile when source is newer than .zwc

# Recompile main zsh files if needed
autoload -U zrecompile

# Recompile main config files
zrecompile -p -R ~/.zshenv -- -M ~/.zshenv.zwc ~/.zshenv
zrecompile -p -R ~/.zprofile -- -M ~/.zprofile.zwc ~/.zprofile
zrecompile -p -R ~/.zshrc -- -M ~/.zshrc.zwc ~/.zshrc

# Recompile all dotfiles modules (quietly)
for file in ${DOTFILES_DIR}/**/*.zsh(N); do
  zrecompile -q -p "$file"
done
