import Foundation

/// A node in the on-disk file tree shown in the sidebar. `children` is
/// computed on demand (not cached) so opening a large case folder doesn't
/// require enumerating the whole tree up front -- only expanded rows pay
/// the `contentsOfDirectory` cost.
struct FileNode: Identifiable, Hashable {
    let url: URL
    var id: URL { url }

    var name: String { url.lastPathComponent }

    var isDirectory: Bool {
        (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
    }

    var children: [FileNode]? {
        guard isDirectory else { return nil }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        return contents
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { FileNode(url: $0) }
    }
}
