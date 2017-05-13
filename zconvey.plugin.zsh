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
# Autoloads
#
autoload zc zc-rename zc-take zc-ls zc-logo zc-logo-all zc-all

#
# Global variables
#

typeset -gi ZCONVEY_ID
typeset -ghH ZCONVEY_FD
typeset -ghH ZCONVEY_IO_DIR="${ZCONVEY_CONFIG_DIR}/io"
typeset -ghH ZCONVEY_LOCKS_DIR="${ZCONVEY_CONFIG_DIR}/locks"
typeset -ghH ZCONVEY_NAMES_DIR="${ZCONVEY_CONFIG_DIR}/names"
typeset -ghH ZCONVEY_OTHER_DIR="${ZCONVEY_CONFIG_DIR}/other"
typeset -ghH ZCONVEY_RUN_SECONDS=$(( SECONDS + 4 ))
typeset -ghH ZCONVEY_SCHEDULE_ORIGIN
command mkdir -p "$ZCONVEY_IO_DIR" "$ZCONVEY_LOCKS_DIR" "$ZCONVEY_NAMES_DIR" "$ZCONVEY_OTHER_DIR"

#
# Helper functions
#

function pinfo() {
    print -- "\033[1;32m$*\033[0m";
}

function pinfo2() {
    print -- "\033[1;33m$*\033[0m";
}

function __zconvey_resolve_name_to_id() {
    local name="$1"

    REPLY=""
    local f
    local -a arr
    for f in "$ZCONVEY_NAMES_DIR"/*.name(N); do
        arr=( ${(@f)"$(<$f)"} )
        arr=( "${(@M)arr:#:$name:}" )
        if [ "${#arr}" != "0" ]; then
            REPLY="${${f:t}%.name}"
        fi
    done
}

function __zconvey_get_name_of_id() {
    local id="$1"

    REPLY=""
    local f="$ZCONVEY_NAMES_DIR/${id}.name"
    if [ -e "$f" ]; then
        REPLY=${(f)"$(<$f)"}
        REPLY="${REPLY#:}"
        REPLY="${REPLY%:}"
        return 0
    fi

    return 1
}

function __zconvey_is_session_active() {
        setopt localoptions extendedglob
        local res idx="$1"

        if [[ "$idx" != <-> || "$idx" = "0" || "$idx" -gt "100" ]]; then
            pinfo "Incorrect sesion ID occured: $idx"
            return 2
        fi

        if [[ "$idx" = "$ZCONVEY_ID" ]]; then
            # Return true - current session is active
            return 0;
        fi

        integer is_locked=0
        local idfile="$ZCONVEY_LOCKS_DIR/zsh_nr${idx}" tmpfd

        if [[ -e "$idfile" ]]; then
            # Use zsystem only if non-blocking call is available (Zsh >= 5.3)
            if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
                zsystem 2>/dev/null flock -t 0 -f tmpfd "$idfile"
                res="$?"
            else
                exec {tmpfd}>"$idfile"
                "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$tmpfd"
                res="$?"

                # Close the fd immediately - unlocking if gained lock
                exec {tmpfd}>&-
            fi

            if [[ "$res" = "101" || "$res" = "1" || "$res" = "2" ]]; then
                is_locked=1
            elif [[ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]]; then
                # Close the lock immediately
                zsystem flock -u "$tmpfd"
            fi
        fi

        return $(( 1-is_locked ))
}

#
# User functions
#

function zc-id() {
    __zconvey_get_name_of_id "$ZCONVEY_ID"
    if [ -z "$REPLY" ]; then
        print "This Zshell's ID: \033[1;33m<${ZCONVEY_ID}>\033[0m (no name assigned)";
    else
        print "This Zshell's ID: \033[1;33m<${ZCONVEY_ID}>\033[0m, name: \033[1;33m${REPLY}\033[0m";
    fi
}

#
# Load configuration
#

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

    local greeting
    zstyle -s ":plugin:zconvey" greeting greeting || greeting="text"
    [[ "$greeting" != "none" && "$greeting" != "text" && "$greeting" != "logo" ]] && greeting="logo"
    ZCONVEY_CONFIG[greeting]="$greeting"

    local timestamp_from
    zstyle -s ":plugin:zconvey" timestamp_from timestamp_from || timestamp_from="datetime"
    [[ "$timestamp_from" != "date" && "$timestamp_from" != "datetime" ]] && timestamp_from="datetime"
    ZCONVEY_CONFIG[timestamp_from]="$timestamp_from"

    local expire_seconds
    zstyle -s ":plugin:zconvey" expire_seconds expire_seconds || expire_seconds="22"
    [[ "$expire_seconds" != <-> ]] && expire_seconds="22"
    ZCONVEY_CONFIG[expire_seconds]="$expire_seconds"

    local output_method
    zstyle -s ":plugin:zconvey" output_method output_method || output_method="feeder"
    [[ "$output_method" != "feeder" && "$output_method" != "zsh" ]] && output_method="feeder"
    ZCONVEY_CONFIG[output_method]="$output_method"
}

#
# Compile myflock
#

# Binary flock command that supports 0 second timeout (zsystem's
# flock in Zsh ver. < 5.3 doesn't) - util-linux/flock stripped
# of some things, compiles hopefully everywhere (tested on OS X,
# Linux, FreeBSD).
if [[ ! -e "${ZCONVEY_REPO_DIR}/myflock/flock" ]]; then
    (
        if zmodload zsh/system; then
            if zsystem flock -t 1 "${ZCONVEY_REPO_DIR}/myflock/flock.c"; then
                echo "\033[1;35m""zdharma\033[0m/\033[1;33m""zconvey\033[0m is building small locking command for you..."
                make -C "${ZCONVEY_REPO_DIR}/myflock"
            fi
        else
            make -C "${ZCONVEY_REPO_DIR}/myflock"
        fi
    )
fi

# A command that feeds data to command line, via TIOCSTI ioctl
if [[ ! -e "${ZCONVEY_REPO_DIR}/feeder/feeder" ]]; then
    (
        if zmodload zsh/system; then
            if zsystem flock -t 1 "${ZCONVEY_REPO_DIR}/myflock/flock.c"; then
                echo "\033[1;35m""zdharma\033[0m/\033[1;33m""zconvey\033[0m is building small command line feeder for you..."
                make -C "${ZCONVEY_REPO_DIR}/feeder"
            fi
        else
            make -C "${ZCONVEY_REPO_DIR}/feeder"
        fi
    )
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
    setopt localoptions extendedglob clobber

    integer idx try_id res
    local fd lockfile

    # When in Tmux or Screen then consider every subshell
    # session as new (no inheritance). TODO: detect exec zsh
    [[ -n "$TMUX" || -n "$STY" ]] && ZCONVEY_ID=0 && ZCONVEY_FD=0

    # Already assigned ID (inherited)?
    idx=0
    if [[ "$ZCONVEY_FD" = <-> && "$ZCONVEY_FD" != "0" && "$ZCONVEY_ID" = <-> && "$ZCONVEY_ID" != "0" ]]; then
        # Inherited FD and ID, no need to perform work
        if print -u "$ZCONVEY_FD" -n 2>/dev/null; then
            # Unbusy this session
            command rm -f "$ZCONVEY_OTHER_DIR/${ZCONVEY_ID}.busy"
            idx=101
        fi
    fi

    # Supported are 100 shells - acquire takes ~400ms max (zsystem's flock)
    for (( ; idx <= 100; idx ++ )); do
        # First (at first loop) try with $ZCONVEY_ID (the case of inherited ID)
        [[ "$idx" = "0" && "$ZCONVEY_ID" = <-> ]] && try_id="$ZCONVEY_ID" || try_id="$idx"
        [[ "$try_id" = "0" ]] && continue

        lockfile="${ZCONVEY_LOCKS_DIR}/zsh_nr${try_id}"
        [[ ! -f "$lockfile" ]] && echo "(created)" > "$lockfile"

        # Use zsystem only if non-blocking call is available (Zsh >= 5.3)
        # -e: preserve file descriptor on exec
        if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
            zsystem 2>/dev/null flock -t 0 -f ZCONVEY_FD -e "$lockfile"
            res="$?"
        else
            exec {ZCONVEY_FD}>"$lockfile"
            "${ZCONVEY_REPO_DIR}/myflock/flock" -nx "$ZCONVEY_FD"
            res="$?"
        fi

        if [[ "$res" = "101" || "$res" = "1" || "$res" = "2" ]]; then
            [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" != "1" ] && exec {ZCONVEY_FD}>&-

            # Is this the special case, i.e. inherition of ZCONVEY_ID?
            # In this case being unable to lock means: we already have
            # that lock, we're at our ZCONVEY_ID, we should use it
            # (process cannot lock files locked by itself, too)
            if [[ "$idx" = "0" ]]; then
                # Export again just to be sure
                export ZCONVEY_ID
                # We will not be able and want to close FD on zshexit
                export ZCONVEY_FD=0
                break
            fi
        else
            # Successful locking in the special case (try_id = ZCONVEY_ID,
            # i.e. idx == 0) means: we don't want to have that lock because
            # it's not inherited (i.e. not already locked by ourselves)
            if [[ "$idx" = "0" ]]; then
                # Release the out of order lock
                exec {ZCONVEY_FD}>&-
                # We will not be able to quick-close FD on zshexit
                ZCONVEY_FD=0
            else
                ZCONVEY_ID=try_id
                # ID and FD will be inherited by subshells and exec zsh calls
                export ZCONVEY_ID
                export ZCONVEY_FD
                break
            fi
        fi
    done

    # Output PID to the locked file. The problem is
    # with Zsh 5.3, 5.3.1 - zsystem's obtained file
    # descriptors cannot be written to
    [[ "$ZCONVEY_FD" -ne "0" ]] && { echo "$$" >&${ZCONVEY_FD} } 2>/dev/null

    # Show what is resolved (ID and possibly a NAME)
    [ "$ZCONVEY_CONFIG[greeting]" = "logo" ] && zc-logo echo
    [ "$ZCONVEY_CONFIG[greeting]" = "text" ] && zc-id
}

#
# Function to paste to command line, used when zle is active
#

function __zconvey_zle_paster() {
    zle .kill-buffer
    LBUFFER+="$*"
    zle .redisplay
    zle .accept-line
}

zle -N __zconvey_zle_paster

#
# Function to check for input commands
#

function __zconvey_on_period_passed() {
    # Reschedule as quickly as possible - user might
    # press Ctrl-C when function is executing
    #
    # Reschedule only if this scheduling sequence
    # comes from approved single origin
    [[ "$ZCONVEY_SCHEDULE_ORIGIN" = "$1" ]] && sched +"${ZCONVEY_CONFIG[check_interval]}" __zconvey_on_period_passed "$ZCONVEY_SCHEDULE_ORIGIN"

    # ..and block Ctrl-C, this function will not
    # stall, no reason for someone to use Ctrl-C
    setopt localtraps; trap '' INT
    setopt localoptions extendedglob clobber

    # Remember when the command was run to detect a possible
    # fail in schedule (because of unlucky Ctrl-C press)
    ZCONVEY_RUN_SECONDS="$SECONDS"

    local fd datafile="${ZCONVEY_IO_DIR}/${ZCONVEY_ID}.io"
    local lockfile="${datafile}.lock"

    # Quick return when no data
    [ ! -e "$datafile" ] && return 0

    # Prepare the lock file, follows locking it
    echo "PID $$ ID $ZCONVEY_ID is reading commands" > "$lockfile"

    # 1. Zsh 5.3 flock that supports timeout 0 (i.e. can be non-blocking)
    if [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "1" ]; then
        if ! zsystem flock -t 0 -f fd "$lockfile"; then
            LANG=C sleep 0.11
            if ! zsystem flock -t 0 -f fd "$lockfile"; then
                # Examine the situation by waiting long
                LANG=C sleep 0.11
                if ! zsystem flock -t 0 -f fd "$lockfile"; then
                    # Waited too long, lock must be broken, remove it
                    command rm -f "$lockfile"
                    # Will handle this input at next call
                    return 2
                fi
            fi
        fi
    # 2. Zsh < 5.3 flock that isn't non-blocking
    elif [ "${ZCONVEY_CONFIG[use_zsystem_flock]}" = "2" ]; then
        if ! zsystem flock -t 1 -f fd "$lockfile"; then
            # Waited too long, lock must be broken, remove it
            command rm -f "$lockfile"
            # Will handle this input at next call
            return 3
        fi
    # 3. Provided flock binary
    else
        exec {fd}>"$lockfile"
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
                    return 4
                fi
            fi
        fi
    fi

    local -a commands
    commands=( "${(@f)"$(<$datafile)"}" )
    command rm -f "$datafile"
    exec {fd}>&-

    # Obtain current time stamp
    local ts
    if [ "$ZCONVEY_CONFIG[timestamp_from]" = "datetime" ]; then
        [[ "${+modules}" = 1 && "${modules[zsh/datetime]}" != "loaded" && "${modules[zsh/datetime]}" != "autoloaded" ]] && zmodload zsh/datetime
        [ "${+modules}" = 0 ] && zmodload zsh/datetime
        ts="$EPOCHSECONDS"
    fi
    # Also a fallback
    if [[ "$ZCONVEY_CONFIG[timestamp_from]" = "date" || -z "$ts" || "$ts" = "0" ]]; then
        ts="$( date +%s )"
    fi

    # Get timestamp of each command, concatenate
    # remaining parts with "; " as separator
    local line cmdts concat_command=""
    for line in "${commands[@]}"; do
        cmdts="${line%% *}"
        concat_command+="; ${line#* }"
    done
    concat_command="${concat_command#; }"
    [[ -o interactive_comments ]] && concat_command+=" ##"

    # TODO: a message that command expired
    if (( ts - cmdts <= ZCONVEY_CONFIG[expire_seconds] )); then
        # Two available methods of outputting the command
        if [ "${ZCONVEY_CONFIG[output_method]}" = "zsh" ]; then
            if zle; then
                zle __zconvey_zle_paster "$concat_command"
            else
                print -zr "$concat_command"
            fi
        else
            "${ZCONVEY_REPO_DIR}/feeder/feeder" "$concat_command"
        fi
    fi

    # Tried: zle .kill-word, .backward-kill-line, .backward-kill-word,
    # .kill-line, .vi-kill-line, .kill-buffer, .kill-whole-line

    return 0
}

#
# Preexec hooks
#

# A hook:
# - detecting failure in re-scheduling
# - marking the shell as busy
__zconvey_preexec_hook() {
    # No periodic run for a long time -> schedule
    if (( SECONDS - ZCONVEY_RUN_SECONDS >= 4 )); then
        # Simulate that __zconvey_on_period_passed was just
        # ran and did re-schedule
        ZCONVEY_RUN_SECONDS="$SECONDS"

        # Schedule with new schedule origin - any duplicate
        # scheduling sequence will be quickly eradicated
        ZCONVEY_SCHEDULE_ORIGIN="$SECONDS"
        sched +"${ZCONVEY_CONFIG[check_interval]}" __zconvey_on_period_passed "$ZCONVEY_SCHEDULE_ORIGIN"
    fi

    # Mark that the shell is busy
    print -r -- "${1[(w)1]}" >! "$ZCONVEY_OTHER_DIR/${ZCONVEY_ID}.busy"
}

# A hook marking the shell as not busy
__zconvey_precmd_hook() {
    command rm -f "$ZCONVEY_OTHER_DIR/${ZCONVEY_ID}.busy"
}

#
# Schedule, other
#

# Not called ideally at say SIGTERM, but
# at least when "exit" is enterred
function __zconvey_zshexit() {
    [[ "$ZCONVEY_FD" != "0" && "$SHLVL" = "1" ]] && exec {ZCONVEY_FD}>&-
}

if ! type sched 2>/dev/null 1>&2; then
    if ! zmodload zsh/sched 2>/dev/null; then
        echo "Zconvey plugin: \033[1;31mzsh/sched module not found, Zconvey cannot work with this Zsh build, aborting\033[0m"
        return 1
    fi
fi

ZCONVEY_SCHEDULE_ORIGIN="$SECONDS"
sched +"${ZCONVEY_CONFIG[check_interval]}" __zconvey_on_period_passed "$ZCONVEY_SCHEDULE_ORIGIN"
autoload -Uz add-zsh-hook
add-zsh-hook zshexit __zconvey_zshexit
add-zsh-hook preexec __zconvey_preexec_hook
add-zsh-hook precmd __zconvey_precmd_hook

zle -N zc-logo
bindkey '^O^I' zc-logo

# vim:ft=zsh
