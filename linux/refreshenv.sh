#!/usr/bin/env bash
# refreshenv - reload PATH into the CURRENT bash session from a fresh login shell
# (picks up changes made by installers to /etc/profile.d, ~/.profile and similar).
# Usage: source refreshenv.sh      (must be sourced, not executed)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Run this with: source ${BASH_SOURCE[0]}   (running it directly cannot change your shell)" >&2
    exit 1
fi
_re_old="$PATH"
_re_new="$(env -i HOME="$HOME" USER="${USER:-}" SHELL="${SHELL:-/bin/bash}" TERM="${TERM:-dumb}" bash -lc 'printf %s "$PATH"' 2>/dev/null)"
if [[ -z "$_re_new" ]]; then
    echo "refreshenv: could not read PATH from a login shell; nothing changed" >&2
else
    PATH="$_re_new"; export PATH; hash -r
    _re_added="$(comm -13 <(tr ':' '\n' <<<"$_re_old" | sort -u) <(tr ':' '\n' <<<"$_re_new" | sort -u))"
    echo "PATH refreshed."
    [[ -n "$_re_added" ]] && sed 's/^/  added: /' <<<"$_re_added"
fi
unset _re_old _re_new _re_added
