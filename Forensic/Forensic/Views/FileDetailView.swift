import SwiftUI

struct FileDetailView: View {
    let fileURL: URL
    let caseRoot: URL?

    var body: some View {
        VStack(spacing: 0) {
            ArtifactInfoBanner(fileURL: fileURL)
            Group {
                switch fileURL.pathExtension.lowercased() {
                case "plist":
                    PlistOutlineView(fileURL: fileURL)
                case "db", "sqlite", "sqlite3", "sqlitedb":
                    SQLiteBrowserView(fileURL: fileURL, caseRoot: caseRoot)
                default:
                    ContentUnavailableView(
                        fileURL.lastPathComponent,
                        systemImage: "doc.questionmark",
                        description: Text("No viewer for this file type yet.")
                    )
                }
            }
        }
        .navigationTitle(fileURL.lastPathComponent)
    }
}
