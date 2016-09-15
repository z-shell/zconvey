## Introduction

Zconvey integrates multiple Zsh sessions. They are given an ID, optionally a NAME (both unique),
and can send commands to each other. This I see as a step towards IDEs – there are multiple windows
that are tied together and have a role assigned.

Video – view on [asciinema](https://asciinema.org/a/85646). You can resize the video by pressing `Ctrl-+` or `Cmd-+`.

[![asciicast](https://asciinema.org/a/85646.png)](https://asciinema.org/a/85646)

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

If using a plugin manager, then `Zplugin` is recommended, but you can use any
other too, and also install with `Oh My Zsh` (by copying directory to
`~/.oh-my-zsh/custom/plugins`).

The plugin integrates with my other plugin [Zsh-Select](https://github.com/psprint/zsh-select).
Install it with e.g. Zplugin to be able to use `-a` option for `zc` command.

### [Zplugin](https://github.com/psprint/zplugin)

Add `zplugin load psprint/zconvey` to your `.zshrc` file. Zplugin will handle
cloning the plugin for you automatically the next time you start zsh. To update
issue `zplugin update psprint/zconvey` (`update-all` can also be used).

### Antigen

Add `antigen bundle psprint/zconvey` to your `.zshrc` file. Antigen will handle
cloning the plugin for you automatically the next time you start zsh.

### Oh-My-Zsh

1. `cd ~/.oh-my-zsh/custom/plugins`
2. `git clone git@github.com:psprint/zconvey.git`
3. Add `zconvey` to your plugin list

### Zgen

Add `zgen load psprint/zconvey` to your .zshrc file in the same place you're doing
your other `zgen load` calls in.

## Information

There are following commands:

- `zc` – sends to other session; use "-a" option to be asked for target and a command to send
- `zc-rename` – assigns name to current or selected session; won't rename if there's a session with the same name
- `zc-take` – takes a name for current or selected sessions, schematically renames any conflicting sessions
- `zc-ls` – lists all active and named sessions
- `zc-id` – shows ID and NAME of current session
- `zc-logo` – the same as `zc-id`, but in a form of an on-screen logo; bound to Ctrl-O Ctrl-I

The main command is `zc`. It is used to execute commands on other sessions. `zc-ls` is the main tool
to obtain overall information on sessions. `zc-take` is a nice rename tool to quickly name a few
sessions. Keyboard shortcut Ctrl-O Ctrl-I will show current session's ID and NAME in form of an
on-screen logo.

