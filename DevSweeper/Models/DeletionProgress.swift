import Foundation

/// Silme işleminin anlık durumu (modal progress için).
struct DeletionProgress: Sendable, Equatable {
    var currentName: String
    var completed: Int
    var total: Int
    var fractionCompleted: Double

    static let idle = DeletionProgress(
        currentName: "",
        completed: 0,
        total: 0,
        fractionCompleted: 0
    )

    var statusText: String {
        guard total > 0 else { return "Hazırlanıyor…" }
        return "\(completed) / \(total)"
    }
}
