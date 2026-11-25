# X セッション開始時に一度実行し、起動時にも MODE / RATE を適用する
# （udev のルールは抜き差し時にしか動かないため）
# パッケージ削除後もこのファイルは残るので、本体の有無を確認する
if [ -x /usr/bin/hdmi-hotplug ]; then
  /usr/bin/hdmi-hotplug >/dev/null 2>&1 &
fi
