# Case 01: USB持ち出し疑惑

## シナリオ

とある会社で、社外秘の設計資料（design-docs）が外部に漏洩した疑いが浮上した。
容疑者は社員 **alice** で、疑惑の日である **2024-05-10** のみ、彼女の業務用Macの
イメージから抽出した以下の証拠が提供されている。

```
evidence/
├── private/var/log/system.log
├── Users/alice/Library/Preferences/com.apple.finder.plist
├── Users/alice/Library/Safari/History.db
└── Library/Application Support/com.apple.TCC/TCC.db
```

あなたはフォレンジック調査官として、これらの証拠から「いつ・何が起きたか」を時系列で
再構築し、aliceが情報を持ち出した証拠を突き止めてください。

> 証拠は学習用に簡略化したスキーマで作成しています。実際のSafari History.db /
> TCC.db は列がもっと多いですが、今回の設問に必要な列だけを残しています。

## 設問

**Q1.** aliceが該当日にMacへログインした時刻は？（UTC, `HH:MM:SS`）

**Q2.** USBドライブがマウントされた時刻とそのボリューム名は？

**Q3.** macOSがそのUSBドライブへのFinderのアクセスを許可した記録（TCC）の時刻は？
      その際に許可されたサービス名（`service`列の値）も答えよ。

**Q4.** aliceがSafariで最後に閲覧した外部サイトのURLと、その閲覧時刻は？
      （＝データを外部に送信した可能性が最も高い操作）

**Q5.** 以上を時系列に並べたとき、「情報持ち出し」が完了したと推定できる時刻は？
      次のフォーマットでフラグを答えよ:

```
flag{YYYY-MM-DD_HH:MM:SS_<アクセス先ドメイン>}
```

## ヒント

- `system.log` に出てくる `BOOT_TIME` / `USER_PROCESS` / `DEAD_PROCESS` /
  `SHUTDOWN_TIME` は、それぞれ起動・ログイン・ログアウト・終了を表す。
- `com.apple.finder.plist` の `FXDesktopVolumePositions` キーは、デスクトップに
  アイコンが表示されたボリューム（＝マウントされた外部ドライブ）の一覧。
- `TCC.db` の `last_modified` と Safari の `visit_time` は、どちらも
  **2001-01-01T00:00:00Z を起点とした秒数**（Apple絶対時間）。Unix時間に変換するには
  `978307200`（2001-01-01のUnix epoch）を足す。
- 表計算やワンライナーで変換してもよい:
  ```sh
  python3 -c "import datetime; print(datetime.datetime.utcfromtimestamp(978307200 + <値>))"
  ```

解けたら [writeup.md](writeup.md) で答え合わせをしてください。
