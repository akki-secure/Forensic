import Foundation
import Testing
@testable import ForensicCore

@Suite("ArtifactCatalog")
struct ArtifactCatalogTests {

    @Test("Matches a straightforward per-user artifact under a mounted case root")
    func matchesSimpleArtifact() {
        let matches = ArtifactCatalog.matches(
            forPath: "/Volumes/Case01/Users/thm/Library/Safari/History.db"
        )
        #expect(matches.map(\.summary) == ["Safari履歴"])
    }

    @Test("A single file can match multiple catalog entries")
    func matchesMultipleEntriesForSameFile() {
        let matches = ArtifactCatalog.matches(
            forPath: "/Users/thm/Library/Application Support/Knowledge/knowledgeC.db"
        )
        #expect(Set(matches.map(\.summary)) == ["アプリ使用時間", "Bluetooth接続"])
    }

    @Test("/var and /private/var are treated as the same path")
    func varAndPrivateVarAreEquivalent() {
        let viaVar = ArtifactCatalog.matches(forPath: "/var/log/system.log")
        let viaPrivateVar = ArtifactCatalog.matches(forPath: "/private/var/log/system.log")
        #expect(!viaVar.isEmpty)
        #expect(Set(viaVar.map(\.summary)) == Set(viaPrivateVar.map(\.summary)))
    }

    @Test("Wildcard path segments (username, plist basename) are matched")
    func matchesWildcardSegments() {
        let matches = ArtifactCatalog.matches(
            forPath: "/private/var/db/dslocal/nodes/Default/users/thm.plist"
        )
        #expect(matches.map(\.summary) == ["ユーザー情報・パスワードヒント"])
    }

    @Test("Unrelated paths produce no matches")
    func noMatchForUnrelatedPath() {
        let matches = ArtifactCatalog.matches(forPath: "/Users/thm/Desktop/notes.txt")
        #expect(matches.isEmpty)
    }
}
