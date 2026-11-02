#!/usr/bin/env bash
# refreshenv - reload PATH into the CURRENT bash session from a fresh login shell
# (picks up changes made by installers to /etc/profile.d, ~/.profile and similar).
# Usage: source refreshenv.sh      (must be sourced, not executed)
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    echo "Run this with: source ${BASH_SOURCE[0]}   (running it directly cannot change your shell)" >&2
    exit 1
fi
# colour only on a terminal, and never when NO_COLOR is set (https://no-color.org); _re_* are unset below
_re_g='' _re_d='' _re_r='' _re_n=''
[[ -t 1 && -z "${NO_COLOR:-}" ]] && _re_g=$'\e[32m' _re_d=$'\e[2m' _re_n=$'\e[0m'
[[ -t 2 && -z "${NO_COLOR:-}" ]] && _re_r=$'\e[31m'
_re_old="$PATH"
_re_new="$(env -i HOME="$HOME" USER="${USER:-}" SHELL="${SHELL:-/bin/bash}" TERM="${TERM:-dumb}" bash -lc 'printf %s "$PATH"' 2>/dev/null)"
if [[ -z "$_re_new" ]]; then
    echo "${_re_r}refreshenv: could not read PATH from a login shell; nothing changed${_re_r:+$'\e[0m'}" >&2
else
    PATH="$_re_new"; export PATH; hash -r
    _re_added="$(comm -13 <(tr ':' '\n' <<<"$_re_old" | sort -u) <(tr ':' '\n' <<<"$_re_new" | sort -u))"
    echo "${_re_g}PATH refreshed.${_re_n}"
    [[ -n "$_re_added" ]] && sed "s/^/  ${_re_d}added:${_re_n} /" <<<"$_re_added"
fi
unset _re_old _re_new _re_added _re_g _re_d _re_r _re_n
