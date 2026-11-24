#!/bin/sh
# HDMI hotplug: adapt X display to connected monitor's resolution

# ===== 設定 =====
# 解像度を固定する場合は MODE を指定（例: 1920x1080）。空ならモニタの推奨解像度（自動）
MODE=""
# リフレッシュレート（例: 60）。空なら指定なし。MODE が空のときは無視される
RATE=""
# ================

export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority

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
