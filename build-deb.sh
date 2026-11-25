#!/bin/sh
# deb パッケージを作成する。使い方: ./build-deb.sh <バージョン>（例: 1.1.0）
set -e
VERSION=${1:?usage: $0 <version>}
cd "$(dirname "$0")"
ROOT=build/hdmi-hotplug
rm -rf build
install -D -m 755 hdmi-hotplug.sh "$ROOT/usr/bin/hdmi-hotplug"
install -D -m 644 95-hdmi-hotplug.rules "$ROOT/lib/udev/rules.d/95-hdmi-hotplug.rules"
install -D -m 644 hdmi-hotplug.default "$ROOT/etc/default/hdmi-hotplug"
install -d "$ROOT/DEBIAN"
sed "s/@VERSION@/$VERSION/" pkg/control > "$ROOT/DEBIAN/control"
install -m 755 pkg/postinst pkg/postrm "$ROOT/DEBIAN/"
echo /etc/default/hdmi-hotplug > "$ROOT/DEBIAN/conffiles"
# releases/latest/download/ で取得できるよう、ファイル名にバージョンを含めない
dpkg-deb --root-owner-group --build "$ROOT" hdmi-hotplug_all.deb
