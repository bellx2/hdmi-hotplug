#!/bin/sh
# HDMI hotplug: adapt X display to connected monitor's resolution

# 既定値。/etc/default/hdmi-hotplug で上書きする
MODE=""
RATE=""
DISPLAY=:0
XAUTHORITY=""
[ -r /etc/default/hdmi-hotplug ] && . /etc/default/hdmi-hotplug

# DISPLAY のセッションを持つユーザーの ~/.Xauthority を返す
detect_xauthority() {
  for s in $(loginctl list-sessions --no-legend | awk '{print $1}'); do
    [ "$(loginctl show-session "$s" -p Display --value)" = "$DISPLAY" ] || continue
    user=$(loginctl show-session "$s" -p Name --value)
    home=$(getent passwd "$user" | cut -d: -f6)
    [ -n "$home" ] && echo "$home/.Xauthority" && return
  done
}

# 設定で指定されていなければ自動検出する
if [ -z "$XAUTHORITY" ]; then
  XAUTHORITY=$(detect_xauthority)
  if [ -z "$XAUTHORITY" ]; then
    logger -t hdmi-hotplug "no session found on DISPLAY=$DISPLAY; set XAUTHORITY in /etc/default/hdmi-hotplug"
    exit 1
  fi
fi
export DISPLAY XAUTHORITY

# 1 回の抜き差しで drm の複数デバイスから change イベントが届き同時に起動されるため、
# 先に起動した 1 つだけ実行する。待機後に状態を読むので後発のイベントの変化も反映される
exec 9>/run/lock/hdmi-hotplug.lock
flock -n 9 || exit 0

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
