import Foundation

/// A known macOS forensic artifact: a file (or a specific key/table inside one)
/// whose presence and contents reveal something about system or user history.
public struct ArtifactDefinition: Identifiable, Hashable, Sendable {
    public let category: String
    public let summary: String
    public let pathPattern: String
    public let detail: String?

    public init(category: String, summary: String, pathPattern: String, detail: String? = nil) {
        self.category = category
        self.summary = summary
        self.pathPattern = pathPattern
        self.detail = detail
    }

    /// Multiple entries (e.g. two keys inside the same plist) can share a
    /// `pathPattern`, so identity also depends on `summary`.
    public var id: String { "\(pathPattern)#\(summary)" }
}

/// Reference table of macOS artifact locations, keyed by the four-step
/// workflow: mount the evidence read-only, locate the artifact, read it with
/// the right parser, then reconstruct who/what/when from it.
public enum ArtifactCatalog {
    public static let all: [ArtifactDefinition] = [
        ArtifactDefinition(
            category: "システム情報",
            summary: "OSインストール日",
            pathPattern: "*/.AppleSetupDone"
        ),
        ArtifactDefinition(
            category: "システム情報",
            summary: "国コード・言語設定",
            pathPattern: "*/Library/Preferences/.GlobalPreferences.plist"
        ),
        ArtifactDefinition(
            category: "システム情報",
            summary: "macOSのバージョン",
            pathPattern: "*/System/Library/CoreServices/SystemVersion.plist"
        ),
        ArtifactDefinition(
            category: "起動・ログイン",
            summary: "起動・終了時刻",
            pathPattern: "*/private/var/log/system.log",
            detail: "BOOT_TIME / SHUTDOWN_TIME の行を探す"
        ),
        ArtifactDefinition(
            category: "起動・ログイン",
            summary: "ログイン/ログアウト",
            pathPattern: "*/private/var/log/system.log",
            detail: "USER_PROCESS / DEAD_PROCESS の行を探す"
        ),
        ArtifactDefinition(
            category: "ネットワーク",
            summary: "ルーターIP（DHCPリース）",
            pathPattern: "*/dhcpclient/leases/*.plist"
        ),
        ArtifactDefinition(
            category: "ユーザー",
            summary: "ユーザー情報・パスワードヒント",
            pathPattern: "*/dslocal/*/users/*.plist"
        ),
        ArtifactDefinition(
            category: "ユーザー",
            summary: "ターミナル履歴",
            pathPattern: "*/.zsh_sessions/*.history"
        ),
        ArtifactDefinition(
            category: "アプリ使用状況",
            summary: "アプリ使用時間",
            pathPattern: "*/Application Support/Knowledge/knowledgeC.db",
            detail: "ZOBJECT ストリーム /app/usage を参照"
        ),
        ArtifactDefinition(
            category: "アプリ使用状況",
            summary: "Bluetooth接続",
            pathPattern: "*/Application Support/Knowledge/knowledgeC.db",
            detail: "ZOBJECT ストリーム /Bluetooth/isConnected を参照"
        ),
        ArtifactDefinition(
            category: "Finder",
            summary: "最近開いたフォルダ",
            pathPattern: "*/Library/Preferences/com.apple.finder.plist",
            detail: "FXRecentFolders キーを参照"
        ),
        ArtifactDefinition(
            category: "Finder",
            summary: "接続したUSB/ドライブ",
            pathPattern: "*/Library/Preferences/com.apple.finder.plist",
            detail: "FXDesktopVolumePositions キーを参照"
        ),
        ArtifactDefinition(
            category: "アプリ管理",
            summary: "インストール履歴",
            pathPattern: "*/Library/Receipts/InstallHistory.plist"
        ),
        ArtifactDefinition(
            category: "アプリ管理",
            summary: "パッケージ詳細",
            pathPattern: "*/private/var/db/receipts/*.plist"
        ),
        ArtifactDefinition(
            category: "アプリ管理",
            summary: "自動起動プログラム",
            pathPattern: "*/Library/LaunchAgents/*"
        ),
        ArtifactDefinition(
            category: "権限",
            summary: "アプリのシステム権限（TCC）",
            pathPattern: "*/Library/Application Support/com.apple.TCC/TCC.db"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "連絡先とのやり取り・本人のメール",
            pathPattern: "*/private/var/db/CoreDuet/People/interactionC.db"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "iCloudアカウント",
            pathPattern: "*/Library/Preferences/MobileMeAccounts.plist"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "通話履歴（電話・FaceTime）",
            pathPattern: "*/Library/Application Support/CallHistoryDB/CallHistory.storedata"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "メッセージ",
            pathPattern: "*/Library/Messages/chat.db"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "カレンダー",
            pathPattern: "*/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "メモ",
            pathPattern: "*/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "リマインダー",
            pathPattern: "*/Library/Group Containers/group.com.apple.reminders/Container_v1/Stores/*"
        ),
        ArtifactDefinition(
            category: "通信・連絡",
            summary: "メール・招待状の添付ファイル",
            pathPattern: "*/Library/Mail/V*/*/Attachments/*"
        ),
        ArtifactDefinition(
            category: "アプリ固有",
            summary: "Microsoft Word のセキュアブックマーク",
            pathPattern: "*/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.microsoft.Word.securebookmarks.plist"
        ),
        ArtifactDefinition(
            category: "ブラウザ",
            summary: "Safari履歴",
            pathPattern: "*/Library/Safari/History.db"
        ),
        ArtifactDefinition(
            category: "メディア",
            summary: "写真",
            pathPattern: "*/Pictures/Photos Library.photoslibrary/database/Photos.sqlite"
        ),
        ArtifactDefinition(
            category: "その他",
            summary: "ウォレット（Passbook/Wallet）",
            pathPattern: "*/Library/Passes/*"
        )
    ]

    /// Returns every catalog entry whose `pathPattern` matches the tail of
    /// `path`. A path can match more than one entry (e.g. knowledgeC.db is
    /// referenced by both the app-usage and Bluetooth rows), so callers
    /// should render the full list, not just the first hit.
    public static func matches(forPath path: String) -> [ArtifactDefinition] {
        let normalizedPath = normalize(path)
        return all.filter { entry in
            globMatches(pattern: normalize(entry.pathPattern), path: normalizedPath)
        }
    }

    /// `/private/var` and `/var` refer to the same location (the latter is a
    /// symlink to the former), and matching should not depend on which form a
    /// mounted case happens to preserve.
    private static func normalize(_ path: String) -> String {
        var result = path.lowercased()
        if result.hasPrefix("/var/") {
            result = "/private" + result
        }
        return result
    }

    /// Minimal glob matcher supporting `*` (matches any run of characters,
    /// including path separators) anchored against the end of `path` -- the
    /// pattern's leading `*` stands in for an arbitrary volume/home prefix.
    private static func globMatches(pattern: String, path: String) -> Bool {
        let escapedParts = pattern.components(separatedBy: "*")
            .map { NSRegularExpression.escapedPattern(for: $0) }
        let regexString = "^" + escapedParts.joined(separator: ".*") + "$"
        guard let regex = try? NSRegularExpression(pattern: regexString) else { return false }
        let range = NSRange(path.startIndex..., in: path)
        return regex.firstMatch(in: path, range: range) != nil
    }
}
