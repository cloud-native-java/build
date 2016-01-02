#!/usr/bin/env bash

#yell() { echo "$0: $*" >&2; }
#die() { yell "$*"; exit 111; }
#try() { "$@" || die "cannot $*"; }

function die() {
    [[ $1 ]] || {
        printf >&2 -- 'Usage:\n\tdie <message> [return code]\n'
        [[ $- == *i* ]] && return 1 || exit 1
    }

    printf >&2 -- '%s' "$1"
    exit ${2:-1}
}

