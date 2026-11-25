# Changelog

## [v1.1.0] - 2026-11-25

### 変更

- 配布形式を deb パッケージ（`hdmi-hotplug_all.deb`）に変更し、`apt` でインストール・削除できるようにした
- 設定（`MODE` / `RATE` / `DISPLAY` / `XAUTHORITY`）を `hdmi-hotplug.sh` から `/etc/default/hdmi-hotplug` に移した。パッケージを更新しても設定が残る
- インストール先を `/usr/bin/hdmi-hotplug` と `/lib/udev/rules.d/` に変更した
- tar.gz 版から移行すると、旧ファイル（`/usr/local/bin/hdmi-hotplug.sh`、`/etc/udev/rules.d/95-hdmi-hotplug.rules`）を自動で削除する

### 削除

- tar.gz での配布と `install.sh` / `uninstall.sh`

## [v1.0.1] - 2026-11-24

### 変更

- リリースノートに `CHANGELOG.md` の該当バージョンの節を使うようにした（GitHub の自動生成ノートは使わない）

## [v1.0.0] - 2026-11-24

### 追加

- HDMI の抜き差しを udev で検知し、接続中のモニタの推奨解像度に自動で切り替える機能
- 2 台目以降のモニタを 1 台目の右側に並べ、外れた出力をオフにする機能
- `hdmi-hotplug.sh` の設定欄（`MODE` / `RATE`）で解像度とリフレッシュレートを固定する機能
  - モニタが対応していない解像度を指定した場合は推奨解像度に切り替え、ログに記録する
- 実行結果を `journalctl -t hdmi-hotplug` で確認できるログ出力
- インストール・アンインストール用スクリプト（`install.sh` / `uninstall.sh`）
- `v` で始まるタグの push で `hdmi-hotplug.tar.gz` を GitHub Releases に公開するワークフロー
