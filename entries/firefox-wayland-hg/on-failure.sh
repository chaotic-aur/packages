#!/usr/bin/env sh
[ -f ../firefox-wayland-hg.log ] && \
telegram-send \
    --config ~/.config/telegram-send-group.conf \
    --sile "Ohayo @thotypous-senpai \"fiwefox-waywand-hg\" buiwd faiwed, hewe's the wog:" \
    -f ../firefox-wayland-hg.log
