# hdmi-hotplug

Raspberry Pi をモニタ未接続で起動したあとに HDMI モニタを接続すると、
解像度が 1024x768 のままで正しく表示されない問題を解決するツールです。
HDMI の抜き差しを udev で検知し、`xrandr --auto` でモニタの推奨解像度に自動で切り替えます。

## 動作確認環境

- Raspberry Pi Compute Module 4
- Raspberry Pi OS (Debian 12 bookworm)
- X11 / LXDE（lightdm で `pi` ユーザーが自動ログイン）
- `vc4-kms-v3d` ドライバ

## ファイル構成

| ファイル | 内容 | インストール先 |
|---|---|---|
| `hdmi-hotplug.sh` | 接続中の出力に `xrandr --auto` をかけて解像度を合わせる本体 | `/usr/local/bin/` |
| `95-hdmi-hotplug.rules` | DRM の change イベント（HDMI の抜き差し）を検知してスクリプトを実行する udev ルール | `/etc/udev/rules.d/` |
| `install.sh` | インストールスクリプト | - |
| `uninstall.sh` | アンインストールスクリプト | - |

## インストール

[Releases](https://github.com/bellx2/hdmi-hotplug/releases) から最新版の `hdmi-hotplug.tar.gz` をダウンロードして展開し、インストールします。
Raspberry Pi 上で次のコマンドを実行してください。

```sh
curl -fsSL -o hdmi-hotplug.tar.gz https://github.com/bellx2/hdmi-hotplug/releases/latest/download/hdmi-hotplug.tar.gz
tar xzf hdmi-hotplug.tar.gz
cd hdmi-hotplug
./install.sh
```

特定のバージョンを使う場合は、URL の `latest/download` を `download/<タグ>`（例: `download/v1.0.0`）に置き換えます。

`sudo` 権限が必要です。再起動は不要で、インストール直後から有効になります。

## アンインストール

インストール時に展開した `hdmi-hotplug` ディレクトリで実行します。

```sh
cd hdmi-hotplug
./uninstall.sh
```

## 動作の仕組み

1. HDMI ケーブルを抜き差しすると、カーネルが DRM の `change` イベントを発行します。
2. udev ルールが `systemd-run` 経由で `hdmi-hotplug.sh` を非同期に起動します。
   udev から直接起動すると処理がタイムアウトで止められることがあるため、この方法を使っています。
3. スクリプトは EDID が読めるようになるまで 2 秒待ってから、次の処理を行います。
   - 接続中の 1 台目を推奨解像度にして primary に設定する
   - 2 台目以降は 1 台目の右側に並べる
   - 外れた出力はオフにする

## 動作確認・ログ

```sh
# 実行ログを見る
journalctl -t hdmi-hotplug

# 抜き差しを擬似的に発生させてテストする
sudo udevadm trigger --action=change --subsystem-match=drm

# 現在の解像度を見る
DISPLAY=:0 xrandr | grep ' connected'
```

## カスタマイズ

### 解像度を固定したい

`hdmi-hotplug.sh` の先頭にある設定欄で指定します。

```sh
MODE="1920x1080"   # 空ならモニタの推奨解像度（自動）
RATE="60"          # 空ならリフレッシュレートは指定しない
```

書き換えたら `./install.sh` を実行し直してください。

- 初期値は `MODE=""`（自動）です。4K モニタでは 3840x2160@30Hz になることがあります。
- 指定できる値は `DISPLAY=:0 xrandr` で確認できます。
- モニタが対応していない解像度を指定した場合は、自動（推奨解像度）に切り替えます。
  そのことはログ（`journalctl -t hdmi-hotplug`）に記録されます。

### ユーザーやディスプレイが違う場合

`hdmi-hotplug.sh` の先頭にある次の 2 行を、環境に合わせて書き換えてください。

```sh
export DISPLAY=:0
export XAUTHORITY=/home/pi/.Xauthority
```

## 注意事項

- X11 専用です。Wayland（labwc / wayfire）では `xrandr` が使えないため動作しません。
- `sudo: unable to resolve host ...` という警告は `/etc/hosts` にホスト名がないために出るもので、
  動作には影響しません。消したい場合は `/etc/hosts` に `127.0.1.1 <ホスト名>` を追記してください。

## リリース手順

`v` で始まるタグを push すると、GitHub Actions（`.github/workflows/release.yml`）が
`hdmi-hotplug.tar.gz` を作成し、GitHub Releases に公開します。

```sh
git tag v1.0.0
git push origin v1.0.0
```
