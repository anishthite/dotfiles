#!/bin/bash

# NOTE: You need the "playerctl" pachage in order for this to work!!!

exec 2>/dev/null

#if [ "$(playerctl status)" = "Playing" ]; then
  title=`exec playerctl -a metadata xesam:title`
  artist=`exec playerctl -a metadata xesam:artist`
  echo "[$artist] $title"
#else
#  echo "No song currently playing"
#fi
