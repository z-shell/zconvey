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

typeset -gi ZCONVEY_ID
typeset -hH ZCONVEY_FD

# Binary flock command that supports 0 second timeout
# (zsystem flock doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere
if [ ! -e "${ZCONVEY_REPO_DIR}/myflock/flock" ]; then
    echo "\033[1;35m""psprint\033[0m/\033[1;33m""zconvey\033[0m is building small locking command for you..."
    make -C "${ZCONVEY_REPO_DIR}/myflock"
fi

# Acquire ID
() {
    local LOCKS_DIR="${ZCONVEY_CONFIG_DIR}/locks"
    mkdir -p "${LOCKS_DIR}"

    integer idx res
    local fd
    
    # Supported are 100 shells - acquire takes ~330ms max
    ZCONVEY_ID="-1"
    for (( idx=1; idx <= 100; idx ++ )); do
        touch "${LOCKS_DIR}/zsh-nr-${idx}"
        exec {ZCONVEY_FD}<"${LOCKS_DIR}/zsh-nr-${idx}"
        "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "${ZCONVEY_FD}"
        res="$?"

        if [ "$res" = "101" ]; then
            exec {ZCONVEY_FD}<&-
        else
            ZCONVEY_ID=idx
            break
        fi
    done

}

function __convey_preexec() {
}

# Not called ideally at say SIGTERM, but
# at least - when "exit" is enterred
function __convey_zshexit() {
    exec {ZCONVEY_FD}<&-
}

autoload add-zsh-hook
add-zsh-hook preexec __convey_preexec
add-zsh-hook zshexit __convey_zshexit
