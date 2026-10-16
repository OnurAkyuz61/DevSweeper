import SwiftUI

struct SweepItemTableView: View {
    let items: [SweepItem]
    let isLoading: Bool
    let isDeleting: Bool
    let deletingItemID: UUID?
    let onClean: (SweepItem) -> Void

    @State private var sortOrder = [KeyPathComparator(\SweepItem.byteCount, order: .reverse)]

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
                Table(sortedItems, sortOrder: $sortOrder) {
                    TableColumn("Öğe Adı", value: \.name) { item in
                        HStack(spacing: 8) {
                            Image(systemName: icon(for: item.kind))
                                .foregroundStyle(.secondary)
                                .frame(width: 16)
                            Text(item.name)
                                .lineLimit(1)
                        }
                    }
                    .width(min: 180, ideal: 240)

                    TableColumn("Dosya Yolu") { item in
                        Text(item.path.path)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .help(item.path.path)
                    }
                    .width(min: 220, ideal: 360)

                    TableColumn("Boyut", value: \.byteCount) { item in
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
                    }
                    .width(90)
                }
            }
        }
    }

    private var sortedItems: [SweepItem] {
        items.sorted(using: sortOrder)
    }

    private func icon(for kind: SweepItem.Kind) -> String {
        switch kind {
        case .derivedData: return "hammer"
        case .archives: return "archivebox"
        case .deviceSupport: return "cable.connector"
        case .simulatorRuntime: return "square.stack.3d.up"
        case .simulatorDevice: return "iphone"
        }
    }
}
