## Zconvey's Zstyles

The values being set are the defaults.

```zsh
zstyle ":plugin:zconvey" check_interval "2"         # How often to check if there are new commands (in seconds)
zstyle ":plugin:zconvey" expire_seconds "22"        # If shell is busy for 22 seconds, the received command will expire and not run
zstyle ":plugin:zconvey" greeting "logo"            # Display logo at Zsh start ("text" – display text, "none" – no greeting)
zstyle ":plugin:zconvey" ask "0"                    # zc won't ask for missing data ("1" has the same effect as always using -a option)
zstyle ":plugin:zconvey" ls_after_rename "0"        # Don't execute zc-ls after doing rename (with zc-rename or zc-take)
zstyle ":plugin:zconvey" use_zsystem_flock "1"      # Should use faster zsystem's flock when it's possible?
                                                    # (default true on Zsh >= 5.3)
zstyle ":plugin:zconvey" output_method "feeder"     # To put commands on command line, Zconvey can use small program "feeder". Or "zsh"
                                                    # method, which currently doesn't automatically run the command – to use when e.g.
                                                    # feeder doesn't build (unlikely) or when occurring any problems with it
zstyle ":plugin:zconvey" timestamp_from "datetime"  # Use zsh/datetime module for obtaining timestamp. "date" – use date command (fork)
```
