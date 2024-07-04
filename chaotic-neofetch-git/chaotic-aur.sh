#!/usr/bin/env bash

case "${1:-}" in
'--official')
    pacman -Sl \
        core extra community multilib testing multilib-testing \
        --color never \
        | awk '/\[installed\]/{print $2}'
    ;;
'--aur')
    pacman -Qqm --color never
    ;;
*)
    pacman -Sl chaotic-aur \
        | awk '/\[installed\]/{print $2}'
    ;;
esac


