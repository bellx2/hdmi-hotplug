#!/bin/sh
# HDMI hotplug: adapt X display to connected monitor's resolution

# 既定値。/etc/default/hdmi-hotplug で上書きする
MODE=""
RATE=""
DISPLAY=:0
XAUTHORITY=/home/pi/.Xauthority
[ -r /etc/default/hdmi-hotplug ] && . /etc/default/hdmi-hotplug
export DISPLAY XAUTHORITY

sleep 2   # wait for EDID to be readable

set_output() {
  out=$1; shift
  if [ -n "$MODE" ]; then
    if [ -n "$RATE" ]; then
      xrandr --output "$out" --mode "$MODE" --rate "$RATE" "$@" && return
    else
      xrandr --output "$out" --mode "$MODE" "$@" && return
    fi
    logger -t hdmi-hotplug "$out: mode $MODE${RATE:+@$RATE} not supported, falling back to auto"
  fi
  xrandr --output "$out" --auto "$@"
}

PRIMARY=""
for out in $(xrandr | awk '/ connected/{print $1}'); do
  if [ -z "$PRIMARY" ]; then
    set_output "$out" --primary; PRIMARY=$out
  else
    set_output "$out" --right-of "$PRIMARY"
  fi
done
for out in $(xrandr | awk '/ disconnected/{print $1}'); do
  xrandr --output "$out" --off
done
logger -t hdmi-hotplug "applied: $(xrandr | grep ' connected')"
