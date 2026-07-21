import SwiftUI
import ForensicCore

/// Shows what the selected file is known to reveal, when it matches an entry
/// in `ArtifactCatalog`. Hidden entirely for files with no known significance.
struct ArtifactInfoBanner: View {
    let fileURL: URL

    private var matches: [ArtifactDefinition] {
        ArtifactCatalog.matches(forPath: fileURL.path)
    }

    var body: some View {
        if !matches.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(matches) { match in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        Text(match.category)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(match.summary)
                            .font(.callout.weight(.medium))
                        if let detail = match.detail {
                            Text(detail)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding([.horizontal, .top], 8)
        }
    }
}
