import SwiftUI

/// Xcode Downloads tarzı modal silme progress penceresi.
/// Açıkken arkadaki UI'ya dokunulamaz.
struct DeletionProgressOverlay: View {
    let progress: DeletionProgress
    let preferTrash: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            VStack(spacing: 0) {
                Text(preferTrash ? String(localized: "Moving to Trash") : String(localized: "Deleting"))
                    .font(.headline)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                Divider()

                HStack(alignment: .top, spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, height: 48)

                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                            .offset(x: 4, y: 4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(progress.currentName.isEmpty ? "…" : progress.currentName)
                            .font(.body.weight(.semibold))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ProgressView(value: progress.fractionCompleted, total: 1)
                            .progressViewStyle(.linear)

                        HStack {
                            Text(preferTrash ? String(localized: "Moving…") : String(localized: "Deleting…"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(progress.statusText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(20)
            }
            .frame(width: 420)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
            .padding(40)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Deletion in progress"))
        .accessibilityValue(progress.statusText)
    }
}

#Preview {
    DeletionProgressOverlay(
        progress: DeletionProgress(
            currentName: "iOS 27.1 Simulator (24A94425)",
            completed: 3,
            total: 10,
            fractionCompleted: 0.3
        ),
        preferTrash: true
    )
}
