# Forensic

macOS 向けのフォレンジック調査支援アプリ。iOS バックアップやファイルシステムから抽出した
plist / SQLite データベースをブラウズ・解析するための SwiftUI アプリと、その解析ロジックを
まとめた Swift パッケージで構成されています。

## 構成

- `Forensic/` — SwiftUI 製の macOS アプリ本体（Xcode プロジェクト）
  - `ContentView.swift`, `RootSplitView.swift` — メインの画面レイアウト
  - `Views/FileTreeSidebar.swift` — ケース内のファイルツリー表示
  - `Views/FileDetailView.swift` — 選択したファイルの詳細表示
  - `Views/PlistOutlineView.swift` — plist ファイルのアウトライン表示
  - `Views/SQLiteBrowserView.swift` — SQLite データベースのブラウズ画面
  - `Models/CaseWorkspace.swift`, `Models/FileNode.swift` — ケース（調査対象一式）とファイルツリーのモデル
- `Packages/ForensicCore/` — アプリから利用する解析ロジックの Swift Package
  - `Sources/ForensicCore/Time/AppleTimestamp.swift` — Apple 独自のタイムスタンプ形式の変換
  - `Sources/ForensicCore/Generic/PlistDocument.swift` — plist ファイルの読み込み・パース
  - `Sources/ForensicCore/Generic/SQLiteBrowser.swift` — SQLite データベースの読み込み（[GRDB.swift](https://github.com/groue/GRDB.swift) を使用）
  - `Tests/ForensicCoreTests/` — 上記に対する単体テスト

## 用語集

Swift / SwiftUI / Xcode に不慣れな方向けの用語集を [GLOSSARY.md](GLOSSARY.md) にまとめています。

## 必要環境

- Xcode / Swift 6.0 以降
- macOS 14 (Sonoma) 以降

## ビルド・実行

```sh
open Forensic/Forensic.xcodeproj
```

Xcode 上でビルド・実行してください。`ForensicCore` パッケージはローカル Swift Package として
アプリから参照されています。

パッケージ単体のテストを実行する場合:

```sh
cd Packages/ForensicCore
swift test
```
