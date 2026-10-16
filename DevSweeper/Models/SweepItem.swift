import Foundation

/// Temizlenebilir bir disk öğesi (önbellek klasörü veya simülatör).
struct SweepItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let byteCount: Int64
    let category: SweepCategory
    let kind: Kind

    enum Kind: String, Hashable, Sendable {
        case derivedData
        case archives
        case deviceSupport
        case simulatorRuntime
        case simulatorDevice
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}

enum SweepError: LocalizedError {
    case pathNotFound(URL)
    case deletionFailed(URL, underlying: Error)
    case accessDenied(URL)
    case partialDeletion([URL])

    var errorDescription: String? {
        switch self {
        case .pathNotFound(let url):
            return "Yol bulunamadı: \(url.path)"
        case .deletionFailed(let url, let underlying):
            return "Silinemedi (\(url.lastPathComponent)): \(underlying.localizedDescription)"
        case .accessDenied(let url):
            return "Erişim reddedildi: \(url.path). Sistem Ayarları > Gizlilik ve Güvenlik > Tam Disk Erişimi üzerinden DevSweeper'a izin verin."
        case .partialDeletion(let urls):
            let names = urls.map(\.lastPathComponent).joined(separator: ", ")
            return "Bazı öğeler silinemedi: \(names)"
        }
    }
}
