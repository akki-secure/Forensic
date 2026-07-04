# Case 02: 潜伏するバックドア

## シナリオ

社員 **bob** のMacの動作が重いという申告があり、調査したところ、身に覚えのない
バックグラウンドプロセスが常駐していることが判明した。マイクが勝手にオンになって
いた形跡もあるとの証言がある。あなたはフォレンジック調査官として、bobのMacの
イメージから抽出した以下の証拠を調べ、いつ・どうやってこのプログラムが送り込まれ、
どうやって再起動後も生き残り続けているのかを明らかにしてください。

```
evidence/
├── private/var/log/system.log
├── Users/bob/.zsh_sessions/501_ttys001.history
├── Users/bob/Library/LaunchAgents/com.update.helper.plist
├── Users/bob/Library/Application Support/Knowledge/knowledgeC.db
├── Library/Receipts/InstallHistory.plist
└── Library/Application Support/com.apple.TCC/TCC.db
```

> 証拠は学習用に簡略化したスキーマで作成しています。実際の `knowledgeC.db` は
> CoreData形式でテーブル名・カラム名がもっと複雑ですが、今回は
> `ZOBJECT(ZSTREAMNAME, ZVALUESTRING, ZSTARTDATE, ZENDDATE)` という
> 簡易スキーマにしています。

## 設問

**Q1.** bobの端末で実行された不審なコマンドの実行時刻（UTC, `HH:MM:SS`）と、
      ダウンロード元のURLは？

**Q2.** そのコマンドの結果としてインストールされたパッケージの識別子(bundle ID)と、
      インストール時刻は？

**Q3.** このプログラムが再起動後も自動的に起動し続けるように仕込まれた
      永続化(persistence)の仕組みは何か。設置されたファイルのパスと、
      自動起動を有効にしているキーを答えよ。

**Q4.** このプログラムに付与されたTCC権限のサービス名と、許可された時刻は？

**Q5.** 翌日(2024-08-03)、bobが再ログインしてからこのプログラムが起動するまでの
      時間は何秒か。この短さから何が言えるか（＝bobが手動で起動したのではないと
      いえる根拠）を説明せよ。

**Q6.** 以上を踏まえ、次のフォーマットでフラグを答えよ
      （＝マイク権限が許可された時刻とバンドルID）:

```
flag{YYYY-MM-DD_HH:MM:SS_<bundle-id>}
```

## ヒント

- `.zsh_sessions/*.history` の各行は `: <UNIX時刻>:0;<コマンド>` という形式。
- `InstallHistory.plist` は配列で、各要素の `date` キーがインストール日時、
  `packageIdentifiers` がインストールされたパッケージのbundle IDのリスト。
- `LaunchAgents/*.plist` の `RunAtLoad` が `true` だと、ログイン時に自動的に
  `ProgramArguments` のプログラムが起動する。`KeepAlive` はプロセスが終了しても
  再起動させ続ける設定。
- `TCC.db` / `knowledgeC.db` の時刻はいずれも **2001-01-01T00:00:00Z を起点とした
  秒数**（Apple絶対時間）。Unix時間に変換するには `978307200` を足す。
  ```sh
  python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + <値>))"
  ```
- `system.log` の2回目の `BOOT_TIME` / `USER_PROCESS` が翌日の再起動・再ログインを表す。

解けたら [writeup.md](writeup.md) で答え合わせをしてください。
