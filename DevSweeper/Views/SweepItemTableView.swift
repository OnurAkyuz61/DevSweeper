import SwiftUI

struct SweepItemTableView: View {
    let items: [SweepItem]
    @Binding var selection: Set<SweepItem.ID>
    let isLoading: Bool
    let isDeleting: Bool
    let deletingItemID: UUID?
    let onClean: (SweepItem) -> Void
    let onCleanSelected: () -> Void

    var body: some View {
        Group {
            if isLoading && items.isEmpty {
                ProgressView(String(localized: "Scanning…"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                ContentUnavailableView(
                    String(localized: "No items found"),
                    systemImage: "tray",
                    description: Text(String(localized: "Nothing to clean in this category."))
                )
            } else {
                VStack(spacing: 0) {
                    headerRow
                    Divider()
                    List(items, children: \.children, selection: $selection) { item in
                        itemRow(item)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                    .onDeleteCommand {
                        onCleanSelected()
                    }
                }
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: 12) {
            Text(String(localized: "Item Name"))
                .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "File Path"))
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)
            Text(String(localized: "Size"))
                .frame(width: 90, alignment: .trailing)
            Text(String(localized: "Action"))
                .frame(width: 88, alignment: .center)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func itemRow(_ item: SweepItem) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: item))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)

                Text(item.name)
                    .lineLimit(1)
                    .fontWeight(item.isGroup ? .semibold : .regular)
                    .help(item.name)

                if item.affectsXcode {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .help(item.xcodeWarning ?? "")
                        .accessibilityLabel(String(localized: "Xcode warning"))
                }

                if item.isGroup, let count = item.children?.count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(.quaternary, in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)

            Text(item.path.path)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .help(item.path.path)
                .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            Text(item.formattedSize)
                .monospacedDigit()
                .frame(width: 90, alignment: .trailing)

            Button {
                onClean(item)
            } label: {
                if deletingItemID == item.id {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 72)
                } else {
                    Label(String(localized: "Delete"), systemImage: "trash")
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)
            .controlSize(.small)
            .disabled(isDeleting || isLoading)
            .help(item.affectsXcode ? (item.xcodeWarning ?? String(localized: "Delete")) : String(localized: "Delete"))
            .frame(width: 88)
        }
        .padding(.vertical, 2)
        .tag(item.id)
        .contextMenu {
            Button(String(localized: "Delete"), role: .destructive) {
                onClean(item)
            }
        }
    }

    private func icon(for item: SweepItem) -> String {
        if !item.isGroup {
            switch item.kind {
            case .derivedData: return "folder"
            case .archives: return "doc.zipper"
            case .deviceSupport: return "internaldrive"
            case .simulatorRuntime: return "square.stack.3d.up"
            case .simulatorDevice: return "iphone"
            }
        }

        switch item.kind {
        case .derivedData: return "hammer"
        case .archives: return "archivebox"
        case .deviceSupport: return "cable.connector"
        case .simulatorRuntime: return "square.stack.3d.up.fill"
        case .simulatorDevice: return "iphone.gen3"
        }
    }
}
