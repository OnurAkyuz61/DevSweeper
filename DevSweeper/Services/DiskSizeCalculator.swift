import Foundation

/// Klasör boyutunu arka planda hesaplayan yardımcı.
/// Projede varsayılan MainActor isolation açık; bu tip UI'dan bağımsız olduğu için nonisolated.
enum DiskSizeCalculator: Sendable {
    /// Verilen URL altındaki tüm dosyaların toplam bayt boyutunu döner.
    nonisolated static func byteCount(of url: URL) -> Int64 {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return 0
        }

        if !isDirectory.boolValue {
            return (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)) ?? 0
        }

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey, .totalFileAllocatedSizeKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        var total: Int64 = 0

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [
                    .isRegularFileKey,
                    .totalFileAllocatedSizeKey,
                    .fileSizeKey
                ])
                guard values.isRegularFile == true else { continue }
                if let allocated = values.totalFileAllocatedSize {
                    total += Int64(allocated)
                } else if let size = values.fileSize {
                    total += Int64(size)
                }
            } catch {
                continue
            }
        }

        return total
    }
}
