import SwiftUI
import ForensicCore

struct PlistOutlineView: View {
    let fileURL: URL

    @State private var root: PlistNode?
    @State private var error: String?

    var body: some View {
        Group {
            if let error {
                ContentUnavailableView(
                    "Couldn't parse plist",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if let root {
                List {
                    PlistNodeRow(key: fileURL.lastPathComponent, node: root)
                }
                .listStyle(.inset)
            } else {
                ProgressView()
            }
        }
        .task(id: fileURL) {
            load()
        }
    }

    private func load() {
        error = nil
        root = nil
        do {
            root = try PlistDocument.parse(contentsOf: fileURL)
        } catch {
            self.error = "\(error)"
        }
    }
}

private struct PlistNodeRow: View {
    let key: String
    let node: PlistNode

    var body: some View {
        switch node {
        case .dictionary(let entries):
            DisclosureGroup {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    PlistNodeRow(key: entry.key, node: entry.value)
                }
            } label: {
                Label("\(key)  (\(entries.count) keys)", systemImage: "folder")
            }
        case .array(let items):
            DisclosureGroup {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    PlistNodeRow(key: "[\(index)]", node: item)
                }
            } label: {
                Label("\(key)  (\(items.count) items)", systemImage: "list.bullet")
            }
        case .keyedArchive(let inner):
            DisclosureGroup {
                PlistNodeRow(key: "unarchived", node: inner)
            } label: {
                Label("\(key)  (NSKeyedArchiver)", systemImage: "archivebox")
            }
        default:
            LabeledContent(key) {
                Text(leafDescription)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var leafDescription: String {
        switch node {
        case .string(let value): return value
        case .number(let value): return String(value)
        case .bool(let value): return value ? "true" : "false"
        case .date(let value): return value.formatted(date: .abbreviated, time: .standard)
        case .data(let value): return "<\(value.count) bytes>"
        case .null: return "null"
        default: return ""
        }
    }
}
