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
                Text(String(format: String(localized: "Total cleanable space: %@"), totalSize))
                    .font(.headline)

                Toggle(isOn: preferTrash) {
                    Text(String(localized: "Safe delete (Trash)"))
                        .font(.caption)
                }
                .toggleStyle(.checkbox)
                .help(String(localized: "When on, items go to Trash; when off, they are permanently deleted."))
            }

            Spacer()

            if selectedCount > 0 {
                Button(role: .destructive) {
                    onCleanSelected()
                } label: {
                    Label(
                        String(format: String(localized: "Clean Selected (%lld)"), selectedCount),
                        systemImage: "trash"
                    )
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
                    Label(String(localized: "Clean All"), systemImage: "trash.fill")
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
            return String(
                format: String(localized: "%lld items · %lld selected (%@)"),
                itemCount,
                selectedCount,
                selectedSize
            )
        }
        return String(format: String(localized: "%lld items"), itemCount)
    }
}
