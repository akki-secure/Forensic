import SwiftUI

struct FileTreeSidebar: View {
    let rootURL: URL
    @Binding var selectedFile: URL?

    var body: some View {
        List(selection: $selectedFile) {
            OutlineGroup([FileNode(url: rootURL)], children: \.children) { node in
                Label(node.name, systemImage: icon(for: node))
                    .tag(node.url)
            }
        }
        .listStyle(.sidebar)
    }

    private func icon(for node: FileNode) -> String {
        guard !node.isDirectory else { return "folder" }
        switch node.url.pathExtension.lowercased() {
        case "plist": return "doc.text"
        case "db", "sqlite", "sqlite3", "sqlitedb": return "cylinder.split.1x2"
        default: return "doc"
        }
    }
}
