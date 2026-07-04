# Case 01 Write-up: USB持ち出し疑惑

## Q1. ログイン時刻

`system.log` を確認する。

```sh
cat evidence/private/var/log/system.log
```

```
[utmpx] BOOT_TIME:     Fri May 10 08:55:03 2024
[utmpx] USER_PROCESS:  alice   console  Fri May 10 09:02:11 2024
[utmpx] DEAD_PROCESS:  alice   console  Fri May 10 09:31:00 2024
[utmpx] SHUTDOWN_TIME: Fri May 10 09:45:22 2024
```

`USER_PROCESS` の行がログインを表す。

**答え: `09:02:11`**

## Q2. USBマウント時刻とボリューム名

`com.apple.finder.plist` を見る。

```sh
plutil -p "evidence/Users/alice/Library/Preferences/com.apple.finder.plist"
```

`FXDesktopVolumePositions` の下に `CONFIDENTIAL_USB` というキーがあり、その中の
`MountedAt` が `2024-05-10T09:14:47Z`。

**答え: ボリューム名 `CONFIDENTIAL_USB`、マウント時刻 `09:14:47`**

## Q3. TCCによるアクセス許可の時刻とサービス名

```sh
sqlite3 "evidence/Library/Application Support/com.apple.TCC/TCC.db" \
  "select service, client, indirect_object_identifier, last_modified from access;"
```

```
kTCCServiceSystemPolicyRemovableVolumes|com.apple.finder|CONFIDENTIAL_USB|737025363
kTCCServiceSystemPolicyDesktopFolder|com.apple.finder||737025400
```

`indirect_object_identifier` が `CONFIDENTIAL_USB` と一致する行が該当。
`last_modified` はApple絶対時間（2001年起点の秒数）なので Unix 時間に変換する。

```sh
python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + 737025363))"
# 2024-05-10 09:16:03
```

**答え: サービス名 `kTCCServiceSystemPolicyRemovableVolumes`、時刻 `09:16:03`**

## Q4. Safariで最後に閲覧した外部サイト

```sh
sqlite3 "evidence/Users/alice/Library/Safari/History.db" \
  "select h.url, v.visit_time from history_visits v
   join history_items h on h.id = v.history_item
   order by v.visit_time;"
```

```
https://internal-wiki.example.com/design-doc|737025755.0
https://file.io/upload|737025850.0
```

最後（＝最も新しい）の行を変換する。

```sh
python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + 737025850))"
# 2024-05-10 09:24:10
```

`file.io` は誰でもファイルを匿名アップロードできる一時ファイル共有サービスであり、
社内wikiの設計資料ページを見た直後にこのサイトへアクセスしていることから、
ここでファイルの外部アップロード（＝持ち出し）が行われたと推定できる。

**答え: `https://file.io/upload`、時刻 `09:24:10`**

## Q5. 時系列の再構築とフラグ

| 時刻(UTC) | 出来事 | 証拠 |
|---|---|---|
| 08:55:03 | Mac起動 | system.log (BOOT_TIME) |
| 09:02:11 | aliceがログイン | system.log (USER_PROCESS) |
| 09:14:47 | `CONFIDENTIAL_USB` をマウント | com.apple.finder.plist |
| 09:16:03 | Finderに外部ドライブへのアクセスを許可（TCC） | TCC.db |
| 09:22:35 | 社内wikiの設計資料ページを閲覧 | Safari History.db |
| 09:24:10 | `file.io`（外部アップロードサイト）へアクセス | Safari History.db |
| 09:31:00 | aliceがログアウト | system.log (DEAD_PROCESS) |
| 09:45:22 | Macがシャットダウン | system.log (SHUTDOWN_TIME) |

USBマウント→アクセス許可→社内資料の閲覧→外部アップロードサイトへのアクセス、という
一連の流れが揃っており、`file.io` へのアクセス時刻が情報持ち出しの完了時刻と推定できる。

**フラグ: `flag{2024-05-10_09:24:10_file.io}`**
