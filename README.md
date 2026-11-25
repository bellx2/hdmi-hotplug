# hdmi-hotplug

Raspberry Pi をモニタ未接続で起動したあとに HDMI モニタを接続すると、
解像度が 1024x768 のままで正しく表示されない問題を解決するツールです。
HDMI の抜き差しを udev で検知し、`xrandr --auto` でモニタの推奨解像度に自動で切り替えます。

## 動作確認環境

- Raspberry Pi Compute Module 4 Rev 1.1
- Raspberry Pi OS (Debian 13 trixie)
- X11 / Raspberry Pi Desktop（`rpd-x` セッション、lightdm で `raspi` ユーザーが自動ログイン）
- `vc4-kms-v3d` ドライバ

## ファイル構成

| ファイル | 内容 | インストール先 |
|---|---|---|
| `hdmi-hotplug.sh` | 接続中の出力に `xrandr --auto` をかけて解像度を合わせる本体 | `/usr/bin/hdmi-hotplug` |
| `95-hdmi-hotplug.rules` | DRM の change イベント（HDMI の抜き差し）を検知してスクリプトを実行する udev ルール | `/lib/udev/rules.d/` |
| `hdmi-hotplug.default` | 設定ファイル（解像度・ディスプレイ） | `/etc/default/hdmi-hotplug` |
| `hdmi-hotplug.xsession` | X セッション開始時に本体を一度実行するフック | `/etc/X11/Xsession.d/95hdmi-hotplug` |
| `pkg/` | deb パッケージの control・postinst・postrm | - |
| `build-deb.sh` | deb パッケージを作成するスクリプト | - |

## インストール

[Releases](https://github.com/bellx2/hdmi-hotplug/releases) から最新版の `hdmi-hotplug_all.deb` をダウンロードしてインストールします。
Raspberry Pi 上で次のコマンドを実行してください。

```sh
curl -fsSL -o /tmp/hdmi-hotplug_all.deb https://github.com/bellx2/hdmi-hotplug/releases/latest/download/hdmi-hotplug_all.deb
sudo apt install /tmp/hdmi-hotplug_all.deb
```

ホームディレクトリに置いた .deb を指定すると、apt が `_apt` ユーザーから読めないという `Notice` を表示します（動作には影響しません）。
`/tmp` に置くとこの表示は出ません。

依存パッケージ（`x11-xserver-utils` など）も自動でインストールされます。
再起動は不要で、インストール直後から有効になります。
アップデートも同じ手順で行えます。`/etc/default/hdmi-hotplug` の設定は引き継がれます。

特定のバージョンを使う場合は、URL の `latest/download` を `download/<タグ>`（例: `download/v1.1.0`）に置き換えます。

### tar.gz 版（v1.0.x）からの移行

上の手順で deb をインストールすると、`install.sh` で入れた旧ファイル
（`/usr/local/bin/hdmi-hotplug.sh` と `/etc/udev/rules.d/95-hdmi-hotplug.rules`）は自動で削除されます。
`hdmi-hotplug.sh` に書き込んでいた設定は引き継がれないため、`/etc/default/hdmi-hotplug` に設定し直してください。

## アンインストール

```sh
sudo apt remove hdmi-hotplug   # 設定ファイルも消す場合は purge
```

## 動作の仕組み

1. HDMI ケーブルを抜き差しすると、カーネルが DRM の `change` イベントを発行します。
2. udev ルールが `systemd-run` 経由で `hdmi-hotplug.sh` を非同期に起動します。
   udev から直接起動すると処理がタイムアウトで止められることがあるため、この方法を使っています。
3. 1 回の抜き差しで drm の複数デバイスからイベントが届き、スクリプトが同時に複数起動されることがあります。
   `flock` で排他し、先に起動した 1 つだけが処理を行います（後から起動したものは何もせず終了します）。
4. スクリプトは EDID が読めるようになるまで 2 秒待ってから、次の処理を行います。
   - 接続中の 1 台目を推奨解像度にして primary に設定する
   - 2 台目以降は 1 台目の右側に並べる
   - 外れた出力はオフにする
5. モニタを接続したまま起動した場合は抜き差しのイベントが起きないため、
   X セッション開始時に `/etc/X11/Xsession.d/95hdmi-hotplug` から一度実行し、起動時にも設定を反映します。
   lightdm の既定の `session-wrapper=/etc/X11/Xsession` を使っている場合に動作します。

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

設定は `/etc/default/hdmi-hotplug` に書きます。変更は次回の HDMI 抜き差しか再起動（再ログイン）から反映され、再インストールは不要です。

```sh
sudo nano /etc/default/hdmi-hotplug
```

### 解像度を固定したい

```sh
MODE="1920x1080"   # 空ならモニタの推奨解像度（自動）
RATE="60"          # 空ならリフレッシュレートは指定しない
```

- 初期値は `MODE=""`（自動）です。4K モニタでは 3840x2160@30Hz になることがあります。
- 指定できる値は `DISPLAY=:0 xrandr` で確認できます。
- モニタが対応していない解像度を指定した場合は、自動（推奨解像度）に切り替えます。
  そのことはログ（`journalctl -t hdmi-hotplug`）に記録されます。

### ユーザーやディスプレイが違う場合

X の認証ファイル（`XAUTHORITY`）は、`DISPLAY` のセッションにログインしているユーザーを
`loginctl` で調べ、そのユーザーの `~/.Xauthority` を自動で使います。ユーザー名が `pi` 以外でも設定は不要です。

ディスプレイ番号が `:0` 以外の場合や、認証ファイルが別の場所にある場合は、次の 2 行を書き換えてください。
`XAUTHORITY` を指定すると、自動検出より優先されます。

```sh
DISPLAY=:0
XAUTHORITY=""   # 例: /home/raspi/.Xauthority
```

該当するセッションが見つからない場合は、何もせずにログ（`journalctl -t hdmi-hotplug`）に記録して終了します。

## 注意事項

- X11 専用です。Wayland（labwc / wayfire）では `xrandr` が使えないため動作しません。
- `sudo: unable to resolve host ...` という警告は `/etc/hosts` にホスト名がないために出るもので、
  動作には影響しません。消したい場合は `/etc/hosts` に `127.0.1.1 <ホスト名>` を追記してください。

## リリース手順

`v` で始まるタグを push すると、GitHub Actions（`.github/workflows/release.yml`）が
`build-deb.sh` で `hdmi-hotplug_all.deb` を作成し、GitHub Releases に公開します。
パッケージのバージョンはタグから先頭の `v` を除いた値（`v1.1.0` なら `1.1.0`）になります。
リリースノートには `CHANGELOG.md` のタグと同じ見出し（例: `## [v1.1.0] - 2026-11-25`）の節が使われます。
該当する節が無いとリリースは失敗するため、タグを付ける前に `CHANGELOG.md` へ追記してコミットしてください。

```sh
git tag v1.1.0
git push origin v1.1.0
```

手元で deb を作る場合は、Debian 系の環境で次を実行します。

```sh
./build-deb.sh 1.1.0
```
