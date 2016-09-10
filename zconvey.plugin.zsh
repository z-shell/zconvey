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
