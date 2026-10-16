import Foundation

/// Temizlenebilir bir disk öğesi (önbellek klasörü, alt öğe veya simülatör).
struct SweepItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let path: URL
    let byteCount: Int64
    let category: SweepCategory
    let kind: Kind
    /// Üst grup (Derived Data vb.) — genişletilebilir; silinince içeriği temizlenir, kök kalır.
    let isGroup: Bool
    /// Silindiğinde Xcode'un yeniden indirme / kurulum istemesine yol açabilir.
    let affectsXcode: Bool
    /// Alt öğeler; `nil` ise yaprak (genişletilemez).
    let children: [SweepItem]?

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

    var xcodeWarning: String? {
        guard affectsXcode else { return nil }
        return "Bu dosyayı silerseniz Xcode’a zarar verebilirsiniz; ilgili bileşenlerin yeniden indirilmesi / yüklenmesi gerekebilir."
    }

    /// Ağacı düz listeye çevirir (seçim / arama için).
    static func flatten(_ items: [SweepItem]) -> [SweepItem] {
        items.flatMap { item in
            [item] + flatten(item.children ?? [])
        }
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
