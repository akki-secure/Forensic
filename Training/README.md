# Training（macフォレンジックCTF練習問題）

CTF形式でmacフォレンジックのスキルを鍛えるための練習ケース集です。各ケースは架空の
シナリオ + ダミーの証拠ファイル一式 + 設問 + 模範解答(write-up)で構成されています。

証拠ファイルは実際のmacOSのディレクトリ構造を模して配置してあるので、`evidence/` を
そのままこのリポジトリのForensicアプリ（`Forensic/Forensic.xcodeproj`）で「ケースフォルダ」
として開くと、実装済みの[アーティファクトカタログ](../Packages/ForensicCore/Sources/ForensicCore/Artifacts/ArtifactCatalog.swift)
が該当ファイルを自動でハイライトします。まずはアプリを使わず手を動かして解いてみて、
その後にアプリでの見え方も確認してみてください。

## ケース一覧

| # | タイトル | 扱うアーティファクト | 難易度 |
|---|---|---|---|
| 01 | [USB持ち出し疑惑](case-01-usb-exfiltration/README.md) | system.log（ログイン/ログアウト）, com.apple.finder.plist（USBマウント履歴）, TCC.db（権限履歴）, Safari History.db（閲覧履歴） | 初級 |
| 02 | [潜伏するバックドア](case-02-launchagent-backdoor/README.md) | .zsh_sessions history（ターミナル履歴）, InstallHistory.plist（インストール履歴）, LaunchAgents（永続化）, TCC.db（権限履歴）, knowledgeC.db（アプリ使用状況）, system.log | 中級 |

## 進め方

1. `case-XX-.../README.md` のシナリオと設問を読む
2. `case-XX-.../evidence/` の中身を `plutil` / `sqlite3` などで直接調べる
3. 自力で解けたら `writeup.md` で答え合わせをする
