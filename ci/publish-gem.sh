#!/usr/bin/env bash

if readlink -f . >/dev/null 2>&1 # {{{ makes readlink work on mac
then
    readlink=readlink
else
    if greadlink -f . >/dev/null 2>&1
    then
        readlink=greadlink
    else
        printf "You must install greadlink to use this (brew install coreutils)\n" >&2
    fi
fi # }}}

# Set here to the full path to this script
me=${BASH_SOURCE[0]}
[ -L "$me" ] && me=$($readlink -f "$me")
here=$(cd "$(dirname "$me")" && pwd)
just_me=$(basename "$me")

: "${GEM_NAME:=feature-flag}"
: "${GIT_ORG:=myprizepicks}"

gem_key='github'
gem_host="https://rubygems.pkg.github.com/$GIT_ORG"

# We only want this part running in CI, with no ~/.gem dir
# For local testing, you should have a ~/.gem/credentials file with
# the keys you need to push to rubygems or github
if [ ! -d ~/.gem ]
then
    if [ -z "$GEM_TOKEN" ]
    then
        printf 'No GEM_TOKEN provided, cannot publish\n' >&2
        exit 1
    fi
    mkdir -p ~/.gem
    printf '%s\n:%s: %s\n' '---' "$gem_key" "$GEM_TOKEN" > ~/.gem/credentials
    chmod 600 ~/.gem/credentials
fi

if [ -f "$here"/../.version.txt ]
then
    version=$(<"$here"/../.version.txt)
else
    version=$(git describe --tags --abbrev=0 | sed -e 's/^v//')
fi

gem="$(printf '%s-%s.gem' "$GEM_NAME" "$version")"

if [[ "${TRACE:-false}" == true || "${ACTIONS_STEP_DEBUG:-false}" == true ]]
then
    printf "DEBUG: [%s] Building And Publishing %s to %s\n" "$just_me" "$gem" "$gem_host" >&2
fi

bundle exec gem build

if [ ! -f "$here"/../"$gem" ]
then
    name_underscore=$(printf '%s' "$GEM_NAME" | tr '-' '_')
    gem="$(printf '%s-%s.gem' "$name_underscore" "$version")"
    printf 'Gem %s not found as %s, trying as %s\n'
    if [ ! -f "$here"/../"$gem" ]
    then
        printf 'Gem %s not found, cannot publish\n' "$gem" >&2
        exit 1
    fi
fi
bundle exec gem push -k "$gem_key" --host "$gem_host" "$gem"

# vim: set foldmethod=marker et ts=4 sts=4 sw=4 ft=bash :
