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

#
# Load configuration
#

typeset -gi ZCONVEY_ID
typeset -hH ZCONVEY_FD
() {
    setopt localoptions extendedglob
    typeset -gA ZCONVEY_CONFIG

    local check_interval
    zstyle -s ":plugin:zconvey" check_interval check_interval || check_interval="2"
    [[ "$check_interval" != <-> ]] && check_interval="2"
    ZCONVEY_CONFIG[check_interval]="$check_interval"

    local use_zsystem_flock
    zstyle -b ":plugin:zconvey" use_zsystem_flock use_zsystem_flock || use_zsystem_flock="yes"
    [ "$use_zsystem_flock" = "yes" ] && use_zsystem_flock="1" || use_zsystem_flock="0"
    ZCONVEY_CONFIG[use_zsystem_flock]="$use_zsystem_flock"
}

#
# Compile myflock
#

# Binary flock command that supports 0 second timeout (zsystem's
# flock in Zsh ver. < 5.3 doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere (tested on OS X,
# Linux).
if [ ! -e "${ZCONVEY_REPO_DIR}/myflock/flock" ]; then
    echo "\033[1;35m""psprint\033[0m/\033[1;33m""zconvey\033[0m is building small locking command for you..."
    make -C "${ZCONVEY_REPO_DIR}/myflock"
fi

# A command that feeds data to command line, via TIOCSTI ioctl
if [ ! -e "${ZCONVEY_REPO_DIR}/feeder/feeder" ]; then
    echo "\033[1;35m""psprint\033[0m/\033[1;33m""zconvey\033[0m is building small command line feeder for you..."
    make -C "${ZCONVEY_REPO_DIR}/feeder"
fi

#
# Acquire ID
#

if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
    autoload is-at-least
    if ! is-at-least 5.3; then
        # Use, but not for acquire
        ZCONVEY_CONFIG[use_zsystem_flock]="2"
    fi

    if ! zmodload zsh/system 2>/dev/null; then
        echo "Zconvey plugin: \033[1;31mzsh/system module not found, will use own flock implementation\033[0m"
        echo "Zconvey plugin: \033[1;31mDisable this warning via: zstyle \":plugin:zconvey\" use_zsystem_flock \"0\"\033[0m"
        ZCONVEY_CONFIG[use_zsystem_flock]="0"
    elif ! zsystem supports flock; then
        echo "Zconvey plugin: \033[1;31mzsh/system module doesn't provide flock, will use own implementation\033[0m"
        echo "Zconvey plugin: \033[1;31mDisable this warning via: zstyle \":plugin:zconvey\" use_zsystem_flock \"0\"\033[0m"
        ZCONVEY_CONFIG[use_zsystem_flock]="0"
    fi
fi

() {
    local LOCKS_DIR="${ZCONVEY_CONFIG_DIR}/locks"
    mkdir -p "${LOCKS_DIR}" "${ZCONVEY_CONFIG_DIR}/io"

    integer idx res
    local fd lockfile
    
    # Supported are 100 shells - acquire takes ~400ms max (zsystem's flock)
    ZCONVEY_ID="-1"
    for (( idx=1; idx <= 100; idx ++ )); do
        lockfile="${LOCKS_DIR}/zsh_nr${idx}"
        command touch "$lockfile"

        # Use zsystem only if non-blocking call is available (Zsh >= 5.3)
        if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
            zsystem flock -f ZCONVEY_ID -r "$i" "$lockfile"
            res="$?"
        else
            exec {ZCONVEY_FD}<"$lockfile"
            "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$ZCONVEY_FD"
            res="$?"
        fi

        if [[ "$res" = "101" || "$res" = "1" || "$res" = "2" ]]; then
            [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" != "1" ] && exec {ZCONVEY_FD}<&-
        else
            ZCONVEY_ID=idx
            break
        fi
    done

    echo "Got ID: $ZCONVEY_ID, FD: $ZCONVEY_FD"
}

#
# Function to check for input commands
#

function __convey_on_period_passed() {
    # Reschedule as quickly as possible - user might
    # press Ctrl-C when function will be working
    sched +"${ZCONVEY_CONFIG[check_interval]}" __convey_on_period_passed

    # ..and block Ctrl-C, this function will not stall
    setopt localtraps; trap '' INT

    local fd datafile="${ZCONVEY_CONFIG_DIR}/io/${ZCONVEY_ID}.io"
    local lockfile="${datafile}.lock"

    # Quick return when no data
    [ ! -e "$datafile" ] && return 1

    # Let's hope next call will have Zle active..
    zle || return 1

    command touch "$lockfile"
    # 1. Zsh 5.3 flock that supports timeout 0 (i.e. can be non-blocking)
    if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
        if ! zsystem flock -t 0 -f fd -r "$lockfile"; then
            LANG=C sleep 0.11
            if ! zsystem flock -t 0 -f fd -r "$lockfile"; then
                # Examine the situation by waiting long
                LANG=C sleep 0.5
                if ! zsystem flock -t 1 -f fd -r "$lockfile"; then
                    # Waited too long, lock must be broken, remove it
                    command rm -f "$lockfile"
                    # Will handle this input at next call
                    return 1
                fi
            fi
        fi
    # 2. Zsh < 5.3 flock that isn't non-blocking
    elif [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "2" ]; then
        if ! zsystem flock -t 2 -f fd -r "$lockfile"; then
            # Waited too long, lock must be broken, remove it
            command rm -f "$lockfile"
            # Will handle this input at next call
            return 1
        fi
    # 3. Provided flock binary
    else
        exec {fd}<"$lockfile"
        "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$fd"
        if [ "$?" = "101" ]; then
            LANG=C sleep 0.11
            "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$fd"
            if [ "$?" = "101" ]; then
                # Examine the situation by waiting long
                sleep 1
                "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$fd"
                if [ "$?" = "101" ]; then
                    # Waited too long, lock must be broken, remove it
                    command rm -f "$lockfile"
                    # Will handle this input at next call
                    return 1
                fi
            fi
        fi
    fi

    local -a commands
    commands=( "${(@f)"$(<$datafile)"}" )
    rm -f "$datafile"
    exec {fd}<&-

    "${ZCONVEY_REPO_DIR}/feeder/feeder" "${(j:; :)commands[@]}"

    zle .accept-line
    # Tried: zle .kill-word, .backward-kill-line, .backward-kill-word,
    # .kill-line, .vi-kill-line, .kill-buffer, .kill-whole-line

    return 0
}

#
# Schedule, other
#

# Not called ideally at say SIGTERM, but
# at least when "exit" is enterred
function __convey_zshexit() {
    exec {ZCONVEY_FD}<&-
}

if ! type sched 2>/dev/null 1>&2; then
    if ! zmodload zsh/sched 2>/dev/null; then
        echo "Zconvey plugin: \033[1;31mzsh/sched module not found, Zconvey cannot work with this Zsh build, aborting\033[0m"
        return 1
    fi
fi

sched +"${ZCONVEY_CONFIG[check_interval]}" __convey_on_period_passed
autoload -Uz add-zsh-hook
add-zsh-hook zshexit __convey_zshexit
