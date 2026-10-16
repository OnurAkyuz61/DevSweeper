import SwiftUI

struct SummaryFooterView: View {
    let itemCount: Int
    let totalSize: String
    let canCleanAll: Bool
    let isDeleting: Bool
    let onCleanAll: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(itemCount) öğe")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Toplam temizlenebilir alan: \(totalSize)")
                    .font(.headline)
            }

            Spacer()

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
}
