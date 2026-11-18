#!/bin/sh
# dunst passes: $1 appname, $2 summary, $3 body, $4 icon, $5 urgency
case "$5" in
    CRITICAL) sound=dialog-warning.oga ;;
    *)        sound=message.oga ;;
esac
pw-play "/usr/share/sounds/freedesktop/stereo/$sound" &
