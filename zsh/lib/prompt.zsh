# Prompt configuration
# Note: OS-specific prompt settings are in os/darwin.zsh or os/linux.zsh
setopt prompt_subst
setopt transient_rprompt

# Default RPROMPT (may be overridden by vcs_info)
RPROMPT="%~"
