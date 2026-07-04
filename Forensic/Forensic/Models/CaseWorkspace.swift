import AppKit
import Observation

/// Holds the case folder the analyst opened and which file within it is
/// currently selected. There is exactly one of these per window.
@Observable
final class CaseWorkspace {
    var rootURL: URL?
    var selectedFile: URL?

    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Case Folder"
        guard panel.runModal() == .OK, let url = panel.urls.first else { return }
        rootURL = url
        selectedFile = nil
    }
}
