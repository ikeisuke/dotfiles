# OPTIONS

## COMPLETION
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_LIST
setopt CORRECT
setopt LIST_PACKED
setopt LIST_TYPES
setopt MAGIC_EQUAL_SUBST
setopt NUMERIC_GLOB_SORT
setopt PRINT_EIGHT_BIT

## SYSTEM
setopt NOBGNICE
setopt NO_HUP
setopt NO_BEEP
setopt NO_LIST_BEEP
setopt NO_FLOW_CONTROL
setopt NOTIFY
setopt INTERACTIVE_COMMENTS

## HISTORY
setopt APPEND_HISTORY              # Append to history file
setopt INC_APPEND_HISTORY_TIME     # Append with timestamps immediately
setopt SHARE_HISTORY               # Share history between sessions
setopt EXTENDED_HISTORY            # Save timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST      # Expire duplicates first when trimming
setopt HIST_IGNORE_SPACE           # Ignore commands starting with space
setopt HIST_REDUCE_BLANKS          # Remove extra blanks
setopt HIST_IGNORE_DUPS            # Don't add duplicate of previous event
setopt HIST_IGNORE_ALL_DUPS        # Remove older duplicates
setopt HIST_FIND_NO_DUPS           # Don't show duplicates in search
setopt HIST_SAVE_NO_DUPS           # Don't save duplicates

## CD
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
