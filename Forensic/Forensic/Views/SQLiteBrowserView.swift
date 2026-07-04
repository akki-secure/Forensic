import SwiftUI
import ForensicCore

struct SQLiteBrowserView: View {
    let fileURL: URL
    let caseRoot: URL?

    @State private var browser: SQLiteBrowser?
    @State private var tables: [String] = []
    @State private var selectedTable: String?
    @State private var columns: [String] = []
    @State private var rows: [IdentifiedSQLiteRow] = []
    @State private var conventions: [String: TimestampConvention] = [:]
    @State private var error: String?
    @State private var sidecarWarning: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let sidecarWarning {
                Label(sidecarWarning, systemImage: "exclamationmark.triangle.fill")
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.2))
            }
            if let error {
                ContentUnavailableView(
                    "Couldn't open database",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else {
                HSplitView {
                    List(tables, id: \.self, selection: $selectedTable) { table in
                        Text(table)
                    }
                    .frame(minWidth: 160, idealWidth: 200, maxWidth: 260)

                    tableContent
                        .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .task(id: fileURL) {
            open()
        }
        .onChange(of: selectedTable) {
            loadRows()
        }
    }

    @ViewBuilder
    private var tableContent: some View {
        if selectedTable != nil {
            Table(rows) {
                TableColumnForEach(columns, id: \.self) { column in
                    TableColumn(column) { row in
                        cellView(row: row, column: column)
                    }
                }
            }
        } else {
            ContentUnavailableView("Select a Table", systemImage: "tablecells")
        }
    }

    @ViewBuilder
    private func cellView(row: IdentifiedSQLiteRow, column: String) -> some View {
        let value = row.row[column] ?? .null
        if let numeric = value.numericValue {
            let convention = conventions[column] ?? AppleTimestamp.guessConvention(forRawValue: numeric)
            VStack(alignment: .leading, spacing: 2) {
                Text(value.displayString)
                Menu(convention.rawValue) {
                    ForEach(TimestampConvention.allCases, id: \.self) { candidate in
                        Button(candidate.rawValue) { conventions[column] = candidate }
                    }
                }
                .menuStyle(.borderlessButton)
                .font(.caption2)
                Text(convention.date(fromRawValue: numeric).formatted(date: .abbreviated, time: .standard))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text(value.displayString)
                .textSelection(.enabled)
        }
    }

    private func open() {
        error = nil
        sidecarWarning = nil
        tables = []
        selectedTable = nil
        rows = []
        columns = []
        conventions = [:]

        if let caseRoot {
            let status = SQLiteBrowser.sidecarStatus(forDatabaseAt: fileURL.path, caseRoot: caseRoot)
            if status.hasOrphanedSidecars {
                sidecarWarning = "A -wal/-shm sidecar for this database exists elsewhere in the case folder but not next to this file. Copy it alongside the .db -- committed data may otherwise be missing from this view."
            }
        }

        do {
            let browser = try SQLiteBrowser(path: fileURL.path)
            self.browser = browser
            tables = try browser.tableNames()
            selectedTable = tables.first
        } catch {
            self.error = "\(error)"
        }
    }

    private func loadRows() {
        guard let browser, let selectedTable else { return }
        conventions = [:]
        do {
            columns = try browser.columnNames(inTable: selectedTable)
            let escapedTable = selectedTable.replacingOccurrences(of: "\"", with: "\"\"")
            let fetched = try browser.execute(sql: "SELECT * FROM \"\(escapedTable)\" LIMIT 500")
            rows = fetched.enumerated().map { IdentifiedSQLiteRow(id: $0.offset, row: $0.element) }
        } catch {
            self.error = "\(error)"
        }
    }
}

private struct IdentifiedSQLiteRow: Identifiable {
    let id: Int
    let row: SQLiteRow
}
