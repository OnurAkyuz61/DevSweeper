import Foundation

/*
 MARK: - Sandbox / Full Disk Access

 Bu servis ~/Library/Developer ve /Library/Developer altındaki
 Xcode / CoreSimulator yollarına erişir.

 1. App Sandbox kapalı olmalı (ENABLE_APP_SANDBOX = NO).
 2. Sandbox açık kalırsa veya TCC engeli varsa:
    Sistem Ayarları → Gizlilik ve Güvenlik → Tam Disk Erişimi
    üzerinden DevSweeper'a izin verin.
 3. /Library/Developer/CoreSimulator/Profiles/Runtimes silmek
    için yönetici (root) yetkisi gerekebilir; bu durumda
    silme başarısız olur ve kullanıcıya alert gösterilir.
 */

/// Xcode önbelleklerini ve CoreSimulator öğelerini tarayıp silen servis.
actor SweepService {
    private let fileManager = FileManager.default

    // MARK: - Known Paths

    private var homeLibraryDeveloper: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Developer", isDirectory: true)
    }

    var derivedDataURL: URL {
        homeLibraryDeveloper.appendingPathComponent("Xcode/DerivedData", isDirectory: true)
    }

    var archivesURL: URL {
        homeLibraryDeveloper.appendingPathComponent("Xcode/Archives", isDirectory: true)
    }

    var deviceSupportURL: URL {
        homeLibraryDeveloper.appendingPathComponent("Xcode/iOS DeviceSupport", isDirectory: true)
    }

    var simulatorDevicesURL: URL {
        homeLibraryDeveloper.appendingPathComponent("CoreSimulator/Devices", isDirectory: true)
    }

    var simulatorRuntimesURL: URL {
        URL(fileURLWithPath: "/Library/Developer/CoreSimulator/Profiles/Runtimes", isDirectory: true)
    }

    // MARK: - Scan

    func scanCacheItems() async -> [SweepItem] {
        async let derived = makeFolderItem(
            name: "Derived Data",
            path: derivedDataURL,
            kind: .derivedData,
            category: .cache
        )
        async let archives = makeFolderItem(
            name: "Archives",
            path: archivesURL,
            kind: .archives,
            category: .cache
        )
        async let deviceSupport = makeFolderItem(
            name: "iOS Device Support",
            path: deviceSupportURL,
            kind: .deviceSupport,
            category: .cache
        )

        let items = await [derived, archives, deviceSupport]
        return items.compactMap { $0 }.sorted { $0.byteCount > $1.byteCount }
    }

    func scanSimulatorItems() async -> [SweepItem] {
        async let runtimes = scanSimulatorRuntimes()
        async let devices = scanSimulatorDevices()

        let combined = await runtimes + devices
        return combined.sorted { $0.byteCount > $1.byteCount }
    }

    // MARK: - Delete

    func delete(_ item: SweepItem) async throws {
        try await deleteContents(at: item.path, removeRoot: item.kind == .simulatorRuntime || item.kind == .simulatorDevice)
    }

    func deleteAll(_ items: [SweepItem]) async throws {
        var failed: [URL] = []

        for item in items {
            do {
                try await delete(item)
            } catch {
                failed.append(item.path)
            }
        }

        if !failed.isEmpty {
            throw SweepError.partialDeletion(failed)
        }
    }

    // MARK: - Private helpers

    private func makeFolderItem(
        name: String,
        path: URL,
        kind: SweepItem.Kind,
        category: SweepCategory
    ) async -> SweepItem? {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        let bytes = DiskSizeCalculator.byteCount(of: path)
        guard bytes > 0 else {
            // Boş klasörleri de gösterelim ki kullanıcı varlığını bilsin.
            return SweepItem(
                id: UUID(),
                name: name,
                path: path,
                byteCount: 0,
                category: category,
                kind: kind
            )
        }

        return SweepItem(
            id: UUID(),
            name: name,
            path: path,
            byteCount: bytes,
            category: category,
            kind: kind
        )
    }

    private func scanSimulatorRuntimes() async -> [SweepItem] {
        let root = simulatorRuntimesURL
        guard let contents = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var items: [SweepItem] = []

        for url in contents {
            let name = readableRuntimeName(from: url)
            let bytes = DiskSizeCalculator.byteCount(of: url)
            items.append(
                SweepItem(
                    id: UUID(),
                    name: name,
                    path: url,
                    byteCount: bytes,
                    category: .simulators,
                    kind: .simulatorRuntime
                )
            )
        }

        return items
    }

    private func scanSimulatorDevices() async -> [SweepItem] {
        let root = simulatorDevicesURL
        guard let deviceDirs = try? fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var items: [SweepItem] = []

        for deviceDir in deviceDirs {
            let plistURL = deviceDir.appendingPathComponent("device.plist")
            guard fileManager.fileExists(atPath: plistURL.path) else { continue }

            let info = parseDevicePlist(at: plistURL)
            let displayName = info.displayName
            let bytes = DiskSizeCalculator.byteCount(of: deviceDir)

            items.append(
                SweepItem(
                    id: UUID(),
                    name: displayName,
                    path: deviceDir,
                    byteCount: bytes,
                    category: .simulators,
                    kind: .simulatorDevice
                )
            )
        }

        return items
    }

    /// device.plist'ten okunabilir isim üretir: "iPhone 16 — iOS 18.0"
    private func parseDevicePlist(at url: URL) -> (displayName: String, runtime: String) {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return (url.deletingLastPathComponent().lastPathComponent, "Unknown")
        }

        let deviceName = (plist["name"] as? String) ?? "Simulator"
        let runtimeID = (plist["runtime"] as? String) ?? ""
        let readableRuntime = readableRuntimeIdentifier(runtimeID)

        if readableRuntime.isEmpty {
            return (deviceName, runtimeID)
        }

        return ("\(deviceName) — \(readableRuntime)", readableRuntime)
    }

    /// com.apple.CoreSimulator.SimRuntime.iOS-18-0 → "iOS 18.0"
    private func readableRuntimeIdentifier(_ identifier: String) -> String {
        // Örn: com.apple.CoreSimulator.SimRuntime.iOS-18-0
        //      com.apple.CoreSimulator.SimRuntime.watchOS-11-0
        let prefix = "com.apple.CoreSimulator.SimRuntime."
        guard identifier.hasPrefix(prefix) else {
            return identifier.isEmpty ? "" : identifier
        }

        let suffix = String(identifier.dropFirst(prefix.count))
        // iOS-18-0 → ["iOS", "18", "0"]
        let parts = suffix.split(separator: "-").map(String.init)
        guard parts.count >= 2 else { return suffix }

        let platform = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(platform) \(version)"
    }

    /// .simruntime paket adından okunabilir isim: "iOS 18.0.simruntime" → "iOS 18.0 Runtime"
    private func readableRuntimeName(from url: URL) -> String {
        var name = url.lastPathComponent
        if name.hasSuffix(".simruntime") {
            name = String(name.dropLast(".simruntime".count))
        }

        // Bazen "iOS 18.0" zaten okunabilir gelir.
        if name.contains(" ") {
            return "\(name) Runtime"
        }

        // iOS-18-0 tarzı
        let readable = readableRuntimeIdentifier("com.apple.CoreSimulator.SimRuntime.\(name)")
        return readable.isEmpty ? "\(name) Runtime" : "\(readable) Runtime"
    }

    /// Klasör içeriğini veya klasörün kendisini siler.
    private func deleteContents(at url: URL, removeRoot: Bool) async throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw SweepError.pathNotFound(url)
        }

        do {
            if removeRoot {
                try fileManager.removeItem(at: url)
            } else if isDirectory.boolValue {
                // DerivedData / Archives / DeviceSupport: kökü bırak, içeriği sil.
                let children = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                for child in children {
                    try fileManager.removeItem(at: child)
                }
            } else {
                try fileManager.removeItem(at: url)
            }
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain && error.code == NSFileWriteNoPermissionError {
                throw SweepError.accessDenied(url)
            }
            throw SweepError.deletionFailed(url, underlying: error)
        }
    }
}
