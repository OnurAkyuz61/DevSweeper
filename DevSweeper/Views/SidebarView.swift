import SwiftUI

struct SidebarView: View {
    @Binding var selection: SweepCategory
    let cacheTotal: Int64
    let simulatorTotal: Int64

    var body: some View {
        List(selection: $selection) {
            Section(String(localized: "Categories")) {
                ForEach(SweepCategory.allCases) { category in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                            Text(category.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.systemImage)
                    }
                    .tag(category)
                    .badge(badge(for: category))
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("DevSweeper")
    }

    private func badge(for category: SweepCategory) -> String {
        let bytes: Int64 = switch category {
        case .cache: cacheTotal
        case .simulators: simulatorTotal
        }
        guard bytes > 0 else { return "" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
