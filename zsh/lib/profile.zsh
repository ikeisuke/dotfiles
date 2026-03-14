# Shell startup profiling
# Usage: ZSH_PROFILE=1 zsh -i -c exit

if [[ -n "$ZSH_PROFILE" ]]; then
  zmodload zsh/zprof
fi

# Convenience function to profile shell startup
zsh-profile() {
  ZSH_PROFILE=1 zsh -i -c 'zprof'
}
