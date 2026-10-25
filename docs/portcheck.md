# portcheck

Tests whether a TCP port on a host accepts connections. A quick replacement for `telnet host port` and a faster alternative to `Test-NetConnection`.

| Platform | Usage |
|---|---|
| Linux | `portcheck.sh HOST PORT [TIMEOUT_SECONDS]` |
| PowerShell | `portcheck.ps1 HOST PORT [TIMEOUT_SECONDS]` |
| cmd | `portcheck HOST PORT [TIMEOUT_SECONDS]` (wrapper) |

Timeout defaults to 3 seconds (1-120).

## Examples
```
portcheck smtp.office365.com 587
OPEN    smtp.office365.com:587
```
```
portcheck 10.0.0.5 3389 1
CLOSED  10.0.0.5:3389 (refused, filtered or no answer within 1s)
```

## Exit codes
`0` open; `2` closed, filtered or timed out; `1` invalid arguments.

## Notes
- TCP only. UDP has no handshake, so a reliable UDP check is not possible this way.
- The host must contain only letters, digits, `.`, `:`, `_` and `-`.
- Linux uses bash's built-in `/dev/tcp`, so no `nc` or `telnet` is needed.
