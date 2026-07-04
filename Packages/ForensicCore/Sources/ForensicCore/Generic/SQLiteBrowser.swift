import Foundation
import GRDB

public enum SQLiteBrowserError: Error, Sendable {
    case notReadOnlySafe(statement: String)
    case openFailed(path: String, underlying: String)
    case queryFailed(underlying: String)
}

/// A single database cell, type-erased for generic table rendering.
public enum SQLiteValue: Sendable {
    case null
    case integer(Int64)
    case real(Double)
    case text(String)
    case blob(Data)

    public var displayString: String {
        switch self {
        case .null: return ""
        case .integer(let value): return String(value)
        case .real(let value): return String(value)
        case .text(let value): return value
        case .blob(let value): return "<\(value.count) bytes>"
        }
    }

    /// Numeric value usable with `TimestampConvention`, when this cell holds
    /// a number. `nil` for text/blob/null cells.
    public var numericValue: Double? {
        switch self {
        case .integer(let value): return Double(value)
        case .real(let value): return value
        default: return nil
        }
    }
}

public struct SQLiteRow: Sendable {
    public let columns: [String]
    public let values: [String: SQLiteValue]

    public subscript(column: String) -> SQLiteValue? { values[column] }
}

public struct SidecarStatus: Sendable {
    public let walPresent: Bool
    public let shmPresent: Bool
    public let walFoundElsewhereInCaseRoot: URL?
    public let shmFoundElsewhereInCaseRoot: URL?

    /// True when a sidecar file is known to exist somewhere in the case root
    /// but is not co-located with the database file, which is exactly the
    /// "copied the .db but forgot -wal/-shm" mistake this warning exists for.
    public var hasOrphanedSidecars: Bool {
        (walFoundElsewhereInCaseRoot != nil && !walPresent)
            || (shmFoundElsewhereInCaseRoot != nil && !shmPresent)
    }
}

/// Read-only wrapper around GRDB for ad hoc inspection of arbitrary SQLite
/// databases -- the in-app equivalent of DB Browser for SQLite.
public final class SQLiteBrowser: Sendable {
    private let dbQueue: DatabaseQueue

    /// Opens `path` read-only. Does not itself search for sidecar files;
    /// call `SQLiteBrowser.sidecarStatus(forDatabaseAt:caseRoot:)` first if a
    /// case root is available, and surface a warning to the user before
    /// opening if `hasOrphanedSidecars` is true.
    public init(path: String) throws {
        var configuration = Configuration()
        configuration.readonly = true
        do {
            dbQueue = try DatabaseQueue(path: path, configuration: configuration)
        } catch {
            throw SQLiteBrowserError.openFailed(path: path, underlying: "\(error)")
        }
    }

    public func tableNames() throws -> [String] {
        try dbQueue.read { db in
            try String.fetchAll(
                db,
                sql: "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name"
            )
        }
    }

    public func columnNames(inTable table: String) throws -> [String] {
        try dbQueue.read { db in
            try db.columns(in: table).map(\.name)
        }
    }

    /// Executes an arbitrary SQL statement. Only `SELECT`/`PRAGMA`/`EXPLAIN`
    /// are permitted by default -- this is inspecting evidence, and even
    /// well-intentioned writes to a working copy should require an explicit
    /// opt-in rather than being the default behavior of a query box.
    public func execute(sql: String, allowWrites: Bool = false) throws -> [SQLiteRow] {
        if !allowWrites {
            let normalized = sql
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
            let readOnlyPrefixes = ["SELECT", "PRAGMA", "EXPLAIN", "WITH"]
            guard readOnlyPrefixes.contains(where: { normalized.hasPrefix($0) }) else {
                throw SQLiteBrowserError.notReadOnlySafe(statement: sql)
            }
        }

        do {
            return try dbQueue.read { db in
                let rows = try Row.fetchAll(db, sql: sql)
                return rows.map { row in
                    var values: [String: SQLiteValue] = [:]
                    var columns: [String] = []
                    for (column, value) in row {
                        columns.append(column)
                        values[column] = Self.sqliteValue(from: value)
                    }
                    return SQLiteRow(columns: columns, values: values)
                }
            }
        } catch let error as SQLiteBrowserError {
            throw error
        } catch {
            throw SQLiteBrowserError.queryFailed(underlying: "\(error)")
        }
    }

    private static func sqliteValue(from value: DatabaseValue) -> SQLiteValue {
        switch value.storage {
        case .null: return .null
        case .int64(let value): return .integer(value)
        case .double(let value): return .real(value)
        case .string(let value): return .text(value)
        case .blob(let value): return .blob(value)
        }
    }

    /// Inspects whether `-wal`/`-shm` sidecar files are co-located with the
    /// database at `databasePath`, and whether same-named sidecars exist
    /// elsewhere under `caseRoot` (a sign the analyst copied the DB file
    /// alone and left the sidecars behind).
    public static func sidecarStatus(forDatabaseAt databasePath: String, caseRoot: URL) -> SidecarStatus {
        let dbURL = URL(fileURLWithPath: databasePath)
        let walURL = dbURL.sidecarURL(suffix: "-wal")
        let shmURL = dbURL.sidecarURL(suffix: "-shm")

        let fm = FileManager.default
        let walPresent = fm.fileExists(atPath: walURL.path)
        let shmPresent = fm.fileExists(atPath: shmURL.path)

        let walElsewhere = walPresent ? nil : findFile(named: walURL.lastPathComponent, under: caseRoot)
        let shmElsewhere = shmPresent ? nil : findFile(named: shmURL.lastPathComponent, under: caseRoot)

        return SidecarStatus(
            walPresent: walPresent,
            shmPresent: shmPresent,
            walFoundElsewhereInCaseRoot: walElsewhere,
            shmFoundElsewhereInCaseRoot: shmElsewhere
        )
    }

    private static func findFile(named name: String, under root: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let fileURL as URL in enumerator where fileURL.lastPathComponent == name {
            return fileURL
        }
        return nil
    }
}

private extension URL {
    /// SQLite sidecar files are named `<db-name>-wal`/`<db-name>-shm`
    /// (hyphen-suffixed, not a `.wal` extension), e.g. `chat.db-wal`.
    func sidecarURL(suffix: String) -> URL {
        deletingLastPathComponent().appendingPathComponent(lastPathComponent + suffix)
    }
}
