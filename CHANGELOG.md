# Changelog

## [v1.0.0] - 2026-11-24

### 追加

- HDMI の抜き差しを udev で検知し、接続中のモニタの推奨解像度に自動で切り替える機能
- 2 台目以降のモニタを 1 台目の右側に並べ、外れた出力をオフにする機能
- `hdmi-hotplug.sh` の設定欄（`MODE` / `RATE`）で解像度とリフレッシュレートを固定する機能
  - モニタが対応していない解像度を指定した場合は推奨解像度に切り替え、ログに記録する
- 実行結果を `journalctl -t hdmi-hotplug` で確認できるログ出力
- インストール・アンインストール用スクリプト（`install.sh` / `uninstall.sh`）
- `v` で始まるタグの push で `hdmi-hotplug.tar.gz` を GitHub Releases に公開するワークフロー
