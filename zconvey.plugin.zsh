#
# No plugin manager is needed to use this file. All that is needed is adding:
#   source {where-zconvey-is}/zconvey.plugin.zsh
#
# to ~/.zshrc.
#

0="${(%):-%N}" # this gives immunity to functionargzero being unset
ZCONVEY_REPO_DIR="${0%/*}"
ZCONVEY_CONFIG_DIR="$HOME/.config/zconvey"

#
# Update FPATH if:
# 1. Not loading with Zplugin
# 2. Not having fpath already updated (that would equal: using other plugin manager)
#

if [[ -z "$ZPLG_CUR_PLUGIN" && "${fpath[(r)$ZCONVEY_REPO_DIR]}" != $ZCONVEY_REPO_DIR ]]; then
    fpath+=( "$ZCONVEY_REPO_DIR" )
fi

typeset -gi ZCONV_ID
typeset -hH ZCONV_FD

# Binary flock command that supports 0 second timeout
# (zsystem flock doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere
if [ ! -e "${ZCONVEY_REPO_DIR}/myflock/flock" ]; then
    echo "\033[1;35m""psprint\033[0m/\033[1;33m""zconvey\033[0m is building small locking command for you..."
    make -C "${ZCONVEY_REPO_DIR}/myflock"
fi

# Acquire ID
() {
    mkdir -p "${ZCONVEY_CONFIG_DIR}/locks"
    integer idx possible_id=1
    local fd
    
    # Supported are 100 shells - acquire takes ~330 ms
    for (( idx=1; idx <= 100; idx ++ )); do
        :
    done
}

function __convey_preexec() {
}

autoload add-zsh-hook
add-zsh-hook preexec __convey_preexec
