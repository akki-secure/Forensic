import SwiftUI

struct RootSplitView: View {
    @State private var workspace = CaseWorkspace()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .toolbar {
            ToolbarItem {
                Button {
                    workspace.openFolder()
                } label: {
                    Label("Open Case Folder", systemImage: "folder.badge.plus")
                }
            }
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if let rootURL = workspace.rootURL {
            FileTreeSidebar(rootURL: rootURL, selectedFile: Bindable(workspace).selectedFile)
        } else {
            ContentUnavailableView(
                "No Case Folder Open",
                systemImage: "folder",
                description: Text("Open a case folder to browse its plist and SQLite files.")
            )
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedFile = workspace.selectedFile {
            FileDetailView(fileURL: selectedFile, caseRoot: workspace.rootURL)
        } else {
            ContentUnavailableView("Select a File", systemImage: "doc")
        }
    }
}
