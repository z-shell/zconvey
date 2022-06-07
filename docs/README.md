<table><tr><td>
<h2 align="center">
  <a href="https://github.com/z-shell/zi">
    <img src="https://github.com/z-shell/zi/raw/main/docs/images/logo.svg" alt="Logo" width="80" height="80" />
  </a>
❮ ZI ❯ Plugin - ZConvey
</h2>
  <a href="https://asciinema.org/a/208206" target="_blank"><img src="https://asciinema.org/a/156726.svg" /></a>
  <b>You can resize the video by pressing <kbd>Ctrl-+</kbd> or <kbd>Cmd-+</kbd></b>
</td></tr></table>

Zconvey integrates multiple Zsh sessions. They are given an ID, optionally a NAME (both unique),
and can send commands to each other. Use this to switch all your Zshells to given directory, via
`zc-all cd $PWD`! Also, there's `zc-bg-notify` **script** (not a function), that will show
notification under prompt of every active Zsh session. You can call this script from any program,
Bash or GUI.

## Zstyles

The values being set are the defaults. They must be set before loading the plugin.

```zsh
zstyle ":plugin:zconvey" check_interval "2"         # How often to check if there are new commands (in seconds)
zstyle ":plugin:zconvey" expire_seconds "22"        # If shell is busy for 22 seconds, the received command will expire and not run
zstyle ":plugin:zconvey" greeting "logo"            # Display logo at Zsh start ("text" – display text, "none" – no greeting)
zstyle ":plugin:zconvey" ask "0"                    # zc won't ask for missing data ("1" has the same effect as always using -a option)
zstyle ":plugin:zconvey" ls_after_rename "0"        # Don't execute zc-ls after doing rename (with zc-rename or zc-take)
zstyle ":plugin:zconvey" use_zsystem_flock "1"      # Should use faster zsystem's flock when it's possible?
                                                    # (default true on Zsh >= 5.3, will revert to mixed zsystem/flock on older Zshells)
zstyle ":plugin:zconvey" output_method "feeder"     # To put commands on command line, Zconvey can use small program "feeder". Or "zsh"
                                                    # method, which currently doesn't automatically run the command – to use when e.g.
                                                    # feeder doesn't build (unlikely) or when occurring any problems with it
zstyle ":plugin:zconvey" timestamp_from "datetime"  # Use zsh/datetime module for obtaining timestamp. "date" – use date command (fork)
```

## Installation

**The plugin is "standalone"**, which means that only sourcing it is needed. So to
install, unpack `zconvey` somewhere and add

```zsh
source {where-zconvey-is}/zconvey.plugin.zsh
```

to `zshrc`.

If using a plugin manager, then `ZI` is recommended, but you can use any
other too, and also install with `Oh My Zsh` (by copying directory to
`~/.oh-my-zsh/custom/plugins`).

The plugin integrates with:

- [z-shell/zsh-select](https://github.com/z-shell/zsh-select). Install it with e.g. ZI to be able to use `-a` option for `zc` command.
- [marzocchi/zsh-notify](https://github.com/marzocchi/zsh-notify), via `cmds/plg-zsh-notify` script.

## [ZI](https://github.com/z-shell/zi)

Add `zi load z-shell/zconvey` to your `.zshrc` file. ZI will clone the plugin
the next time you start zsh. To update issue `zi update z-shell/zconvey`.

ZI can load in [turbo mode](https://z-shell.pages.dev/docs/getting_started/overview#turbo-mode-zsh--53),
below is an example configuration, together with adding `zc-bg-notify` to `$PATH`:

```zsh
zi ice wait"0"
zi light z-shell/zconvey
zi ice wait"0" as"command" pick"cmds/zc-bg-notify" silent
zi light z-shell/zconvey
```

## Zinit

Add `zinit load z-shell/zconvey` to your `.zshrc` file. ZI will clone the plugin
the next time you start zsh. To update issue `zinit update z-shell/zconvey`.

## Antigen

Add `antigen bundle z-shell/zconvey` to your `.zshrc` file. Antigen will handle
cloning the plugin for you automatically the next time you start zsh.

## Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:z-shell/zconvey.git`
3. Add `zconvey` to your plugin list

## Zgen

Add `zgen load z-shell/zconvey` to your .zshrc file in the same place you're doing
your other `zgen load` calls in.

# Information

There are following commands:

- `zc` – sends to other session; use "-a" option to be asked for target and a command to send
- `zc-all` – the same as `zc`, but targets are all other active sessions (with `-f` also busy sessions)
- `zc-rename` – assigns name to current or selected session; won't rename if there's a session with the same name
- `zc-take` – takes a name for current or selected sessions, schematically renames any conflicting sessions
- `zc-ls` – lists all active and named sessions
- `zc-id` – shows ID and NAME of current session
- `zc-logo` – the same as `zc-id`, but in a form of an on-screen logo; bound to Ctrl-O Ctrl-I
- `zc-bg-notify` – in subdirectory `cmds`, link it to `/usr/local/bin`, etc. or load with e.g. ZI

The main command is `zc` (yet it is rather rarely used, I'm always sending to all sessions with `zc-all`).
It is used to execute commands on other sessions. `zc-ls` is the main tool
to obtain overall information on sessions. `zc-take` is a nice rename tool to quickly name a few
sessions. Keyboard shortcut Ctrl-O Ctrl-I will show current session's ID and NAME in form of an
on-screen logo.
