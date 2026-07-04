import Foundation
import Testing
@testable import ForensicCore

@Suite("SQLiteBrowser")
struct SQLiteBrowserTests {
    private func fixtureURL(_ name: String, extension ext: String) -> URL {
        Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")!
    }

    @Test("Lists table names")
    func listsTables() throws {
        let browser = try SQLiteBrowser(path: fixtureURL("sample", extension: "sqlite").path)
        #expect(try browser.tableNames() == ["messages"])
    }

    @Test("Lists column names for a table")
    func listsColumns() throws {
        let browser = try SQLiteBrowser(path: fixtureURL("sample", extension: "sqlite").path)
        #expect(try browser.columnNames(inTable: "messages") == ["id", "text", "date"])
    }

    @Test("Executes a SELECT and returns rows with typed values")
    func executesSelect() throws {
        let browser = try SQLiteBrowser(path: fixtureURL("sample", extension: "sqlite").path)
        let rows = try browser.execute(sql: "SELECT * FROM messages ORDER BY id")

        #expect(rows.count == 2)
        #expect(rows[0]["text"]?.displayString == "hello")
        #expect(rows[0]["date"]?.numericValue == 767338283856999936)
        #expect(rows[1]["text"]?.displayString == "world")
    }

    @Test("A raw chat.db-style date column converts to the correct real-world date via AppleTimestamp")
    func integratesWithTimestampConversion() throws {
        let browser = try SQLiteBrowser(path: fixtureURL("sample", extension: "sqlite").path)
        let rows = try browser.execute(sql: "SELECT * FROM messages WHERE id = 2")
        let raw = rows[0]["date"]!.numericValue!
        let date = AppleTimestamp.fromChatDB(Int64(raw))

        // Sanity check: this should land in 2025, not near the 1970 or 2001 epoch,
        // and not billions of years away (the seconds-vs-nanoseconds bug class).
        let year = Calendar(identifier: .gregorian).component(.year, from: date)
        #expect(year == 2025)
    }

    @Test("Rejects non-SELECT statements by default")
    func rejectsWritesByDefault() throws {
        let browser = try SQLiteBrowser(path: fixtureURL("sample", extension: "sqlite").path)
        #expect(throws: SQLiteBrowserError.self) {
            try browser.execute(sql: "DELETE FROM messages")
        }
    }

    @Test("sidecarStatus reports missing -wal/-shm as not present and not found elsewhere")
    func sidecarStatusNoSidecars() throws {
        let dbURL = fixtureURL("sample", extension: "sqlite")
        let caseRoot = dbURL.deletingLastPathComponent()
        let status = SQLiteBrowser.sidecarStatus(forDatabaseAt: dbURL.path, caseRoot: caseRoot)

        #expect(status.walPresent == false)
        #expect(status.shmPresent == false)
        #expect(status.hasOrphanedSidecars == false)
    }
}
