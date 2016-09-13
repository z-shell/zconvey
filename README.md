## Introduction

Zconvey integrates multiple Zsh sessions. They are given an ID, optionally a NAME (both unique),
and can send commands to each other.

[![asciicast](https://asciinema.org/a/ayklrum7g4ut2hpt7mg6j0nzj.png)](https://asciinema.org/a/ayklrum7g4ut2hpt7mg6j0nzj)

## Zstyles

The values being set are the defaults.

```zsh
zstyle ":plugin:zconvey" check_interval "2"         # How often to check if there are new commands (in seconds)
zstyle ":plugin:zconvey" use_zsystem_flock "1"      # Should use faster zsystem's flock when it's possible?
                                                    # (default true on Zsh >= 5.3)
zstyle ":plugin:zconvey" greeting "logo"            # Display logo at Zsh start ("text" – display text, "none" – no greeting)
zstyle ":plugin:zconvey" ls_after_rename "0"        # Don't execute zc-ls after doing rename (with zc-rename or zc-take)
zstyle ":plugin:zconvey" ask "0"                    # zc won't ask for missing data ("1" has the same effect as always using -a option)
zstyle ":plugin:zconvey" timestamp_from "datetime"  # Use zsh/datetime module for obtaining timestamp. "date" – use date command (fork)
```
