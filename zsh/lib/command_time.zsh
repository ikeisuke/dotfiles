# Command execution time tracking
# Shows start, end, and duration for each command
# Uses zsh built-in EPOCHSECONDS for better performance

zmodload zsh/datetime

# Capture timestamp before command execution
function __record_command_start_time() {
  COMMAND_START_EPOCH=$EPOCHSECONDS
  COMMAND_START_TIME=${(%):-%D{%T}}
}

# Display start, end timestamps and duration after command execution
function __show_command_time() {
  if [[ -n $COMMAND_START_EPOCH ]]; then
    local end_epoch=$EPOCHSECONDS
    local end_time=${(%):-%D{%T}}
    local duration=$((end_epoch - COMMAND_START_EPOCH))
    print -P "%F{242}[start: ${COMMAND_START_TIME}, end: ${end_time}, took: ${duration}s]%f"
    unset COMMAND_START_EPOCH COMMAND_START_TIME
  fi
}

autoload -Uz add-zsh-hook
add-zsh-hook preexec __record_command_start_time
add-zsh-hook precmd __show_command_time
