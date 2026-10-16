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
                ProgressView("Taranıyor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if items.isEmpty {
                ContentUnavailableView(
                    "Öğe bulunamadı",
                    systemImage: "tray",
                    description: Text("Bu kategoride temizlenecek bir şey yok.")
                )
            } else {
                Table(items, children: \.children, selection: $selection) {
                    TableColumn("Öğe Adı") { item in
                        HStack(spacing: 6) {
                            Image(systemName: icon(for: item))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)

                            Text(item.name)
                                .lineLimit(1)
                                .fontWeight(item.isGroup ? .semibold : .regular)

                            if item.affectsXcode {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .help(item.xcodeWarning ?? "")
                                    .accessibilityLabel("Xcode uyarısı")
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
                    }
                    .width(min: 200, ideal: 280)

                    TableColumn("Dosya Yolu") { item in
                        Text(item.path.path)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .help(item.path.path)
                    }
                    .width(min: 200, ideal: 340)

                    TableColumn("Boyut") { item in
                        Text(item.formattedSize)
                            .monospacedDigit()
                    }
                    .width(min: 80, ideal: 100)

                    TableColumn("İşlem") { item in
                        Button {
                            onClean(item)
                        } label: {
                            if deletingItemID == item.id {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .disabled(isDeleting || isLoading)
                        .controlSize(.small)
                        .help(item.affectsXcode ? (item.xcodeWarning ?? "Sil") : "Sil")
                    }
                    .width(90)
                }
                .onDeleteCommand {
                    onCleanSelected()
                }
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
