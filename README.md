## Introduction

Zconvey integrates multiple Zsh sessions. They are given an ID, optionally a NAME, and can
send commands to each other.

[![asciicast](https://asciinema.org/a/ayklrum7g4ut2hpt7mg6j0nzj.png)](https://asciinema.org/a/ayklrum7g4ut2hpt7mg6j0nzj)

## Zstyles

The values being set are the defaults.

```zsh
zstyle ":plugin:zconvey" check_interval "2"         # How often to check if there are new commands (in seconds)
zstyle ":plugin:zconvey" use_zsystem_flock "1"      # Should use faster zsystem's flock when it's possible?
                                                    # (default true on Zsh >= 5.3)
```
