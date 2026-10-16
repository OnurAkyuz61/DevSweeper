import SwiftUI

struct SummaryFooterView: View {
    let itemCount: Int
    let totalSize: String
    let selectedCount: Int
    let selectedSize: String
    let canCleanSelected: Bool
    let canCleanAll: Bool
    let isDeleting: Bool
    let preferTrash: Binding<Bool>
    let onCleanSelected: () -> Void
    let onCleanAll: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Toplam temizlenebilir alan: \(totalSize)")
                    .font(.headline)

                Toggle(isOn: preferTrash) {
                    Text("Güvenli silme (Çöp Kutusu)")
                        .font(.caption)
                }
                .toggleStyle(.checkbox)
                .help("Açıkken öğeler Çöp Kutusu'na taşınır; kapalıyken kalıcı silinir.")
            }

            Spacer()

            if selectedCount > 0 {
                Button(role: .destructive) {
                    onCleanSelected()
                } label: {
                    Label("Seçilenleri Temizle (\(selectedCount))", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .disabled(!canCleanSelected)
                .keyboardShortcut(.delete, modifiers: [])
            }

            Button(role: .destructive) {
                onCleanAll()
            } label: {
                if isDeleting {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.horizontal, 8)
                } else {
                    Label("Tümünü Temizle", systemImage: "trash.fill")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(!canCleanAll)
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
        }
        .padding()
        .background(.bar)
    }

    private var summaryLine: String {
        if selectedCount > 0 {
            return "\(itemCount) öğe · \(selectedCount) seçili (\(selectedSize))"
        }
        return "\(itemCount) öğe"
    }
}
