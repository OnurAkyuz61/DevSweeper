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
        async let derived = makeGroupItem(
            name: String(localized: "Derived Data"),
            path: derivedDataURL,
            kind: .derivedData,
            category: .cache,
            affectsXcode: false
        )
        async let archives = makeGroupItem(
            name: String(localized: "Archives"),
            path: archivesURL,
            kind: .archives,
            category: .cache,
            affectsXcode: false
        )
        async let deviceSupport = makeGroupItem(
            name: String(localized: "iOS Device Support"),
            path: deviceSupportURL,
            kind: .deviceSupport,
            category: .cache,
            affectsXcode: true
        )

        let items = await [derived, archives, deviceSupport]
        return items.compactMap { $0 }.sorted { $0.byteCount > $1.byteCount }
    }

    func scanSimulatorItems() async -> [SweepItem] {
        async let runtimeChildren = scanSimulatorRuntimes()
        async let deviceChildren = scanSimulatorDevices()

        let runtimes = await runtimeChildren
        let devices = await deviceChildren
        var result: [SweepItem] = []

        if fileManager.fileExists(atPath: simulatorRuntimesURL.path) || !runtimes.isEmpty {
            let total = runtimes.reduce(Int64(0)) { $0 + $1.byteCount }
            result.append(
                SweepItem(
                    id: UUID(),
                    name: String(localized: "Simulator Runtimes"),
                    path: simulatorRuntimesURL,
                    byteCount: total,
                    category: .simulators,
                    kind: .simulatorRuntime,
                    isGroup: true,
                    affectsXcode: true,
                    children: runtimes
                )
            )
        }

        if fileManager.fileExists(atPath: simulatorDevicesURL.path) || !devices.isEmpty {
            let total = devices.reduce(Int64(0)) { $0 + $1.byteCount }
            result.append(
                SweepItem(
                    id: UUID(),
                    name: String(localized: "Simulator Devices"),
                    path: simulatorDevicesURL,
                    byteCount: total,
                    category: .simulators,
                    kind: .simulatorDevice,
                    isGroup: true,
                    affectsXcode: false,
                    children: devices
                )
            )
        }

        return result.sorted { $0.byteCount > $1.byteCount }
    }

    // MARK: - Delete

    /// Varsayılan: Çöp Kutusu'na taşır (güvenli silme).
    func delete(_ item: SweepItem, preferTrash: Bool = true) async throws {
        try await deleteContents(at: item.path, removeRoot: !item.isGroup, preferTrash: preferTrash)
    }

    /// Öğeleri siler; her birim tamamlandıkça `onProgress` çağrılır (0...1).
    func deleteAll(
        _ items: [SweepItem],
        preferTrash: Bool = true,
        onProgress: (@Sendable (DeletionProgress) async -> Void)? = nil
    ) async throws {
        let targets = Self.compactTargets(items)
        let units = workUnits(for: targets)
        let total = max(units.count, 1)
        var failed: [URL] = []
        var completed = 0

        if let onProgress {
            await onProgress(
                DeletionProgress(
                    currentName: units.first?.name ?? String(localized: "Deleting…"),
                    completed: 0,
                    total: total,
                    fractionCompleted: 0
                )
            )
        }

        for unit in units {
            if let onProgress {
                await onProgress(
                    DeletionProgress(
                        currentName: unit.name,
                        completed: completed,
                        total: total,
                        fractionCompleted: Double(completed) / Double(total)
                    )
                )
            }

            do {
                try await deleteContents(
                    at: unit.url,
                    removeRoot: unit.removeRoot,
                    preferTrash: preferTrash
                )
            } catch {
                failed.append(unit.url)
            }

            completed += 1

            if let onProgress {
                await onProgress(
                    DeletionProgress(
                        currentName: unit.name,
                        completed: completed,
                        total: total,
                        fractionCompleted: Double(completed) / Double(total)
                    )
                )
            }
        }

        if !failed.isEmpty {
            throw SweepError.partialDeletion(failed)
        }
    }

    private struct WorkUnit {
        let name: String
        let url: URL
        let removeRoot: Bool
    }

    /// Grupları alt öğelere bölerek progress çubuğu için anlamlı adımlar üretir.
    private func workUnits(for items: [SweepItem]) -> [WorkUnit] {
        var units: [WorkUnit] = []

        for item in items {
            if item.isGroup {
                if let children = item.children, !children.isEmpty {
                    for child in children {
                        units.append(WorkUnit(name: child.name, url: child.path, removeRoot: true))
                    }
                } else if let contents = try? fileManager.contentsOfDirectory(
                    at: item.path,
                    includingPropertiesForKeys: nil,
                    options: []
                ), !contents.isEmpty {
                    for url in contents {
                        units.append(WorkUnit(name: url.lastPathComponent, url: url, removeRoot: true))
                    }
                } else {
                    units.append(WorkUnit(name: item.name, url: item.path, removeRoot: false))
                }
            } else {
                units.append(WorkUnit(name: item.name, url: item.path, removeRoot: true))
            }
        }

        return units
    }

    /// Üst grup seçiliyse alt öğeleri tekrar silmeye çalışma.
    nonisolated static func compactTargets(_ items: [SweepItem]) -> [SweepItem] {
        var childIDsUnderSelectedGroups: Set<UUID> = []
        for item in items where item.isGroup {
            for child in SweepItem.flatten(item.children ?? []) {
                childIDsUnderSelectedGroups.insert(child.id)
            }
        }
        return items.filter { !childIDsUnderSelectedGroups.contains($0.id) }
    }

    // MARK: - Private helpers

    private func makeGroupItem(
        name: String,
        path: URL,
        kind: SweepItem.Kind,
        category: SweepCategory,
        affectsXcode: Bool
    ) async -> SweepItem? {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return nil
        }

        let children = listImmediateChildren(
            of: path,
            kind: kind,
            category: category,
            affectsXcode: affectsXcode
        )
        let bytes = children.isEmpty
            ? DiskSizeCalculator.byteCount(of: path)
            : children.reduce(Int64(0)) { $0 + $1.byteCount }

        return SweepItem(
            id: UUID(),
            name: name,
            path: path,
            byteCount: bytes,
            category: category,
            kind: kind,
            isGroup: true,
            affectsXcode: affectsXcode,
            children: children
        )
    }

    private func listImmediateChildren(
        of parent: URL,
        kind: SweepItem.Kind,
        category: SweepCategory,
        affectsXcode: Bool
    ) -> [SweepItem] {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: parent,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents.map { url in
            let bytes = DiskSizeCalculator.byteCount(of: url)
            return SweepItem(
                id: UUID(),
                name: url.lastPathComponent,
                path: url,
                byteCount: bytes,
                category: category,
                kind: kind,
                isGroup: false,
                affectsXcode: affectsXcode,
                children: nil
            )
        }
        .sorted { $0.byteCount > $1.byteCount }
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

        return contents.map { url in
            SweepItem(
                id: UUID(),
                name: readableRuntimeName(from: url),
                path: url,
                byteCount: DiskSizeCalculator.byteCount(of: url),
                category: .simulators,
                kind: .simulatorRuntime,
                isGroup: false,
                affectsXcode: true,
                children: nil
            )
        }
        .sorted { $0.byteCount > $1.byteCount }
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

        return deviceDirs.compactMap { deviceDir -> SweepItem? in
            let plistURL = deviceDir.appendingPathComponent("device.plist")
            guard fileManager.fileExists(atPath: plistURL.path) else { return nil }

            let info = parseDevicePlist(at: plistURL)
            return SweepItem(
                id: UUID(),
                name: info.displayName,
                path: deviceDir,
                byteCount: DiskSizeCalculator.byteCount(of: deviceDir),
                category: .simulators,
                kind: .simulatorDevice,
                isGroup: false,
                affectsXcode: false,
                children: nil
            )
        }
        .sorted { $0.byteCount > $1.byteCount }
    }

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

    private func readableRuntimeIdentifier(_ identifier: String) -> String {
        let prefix = "com.apple.CoreSimulator.SimRuntime."
        guard identifier.hasPrefix(prefix) else {
            return identifier.isEmpty ? "" : identifier
        }

        let suffix = String(identifier.dropFirst(prefix.count))
        let parts = suffix.split(separator: "-").map(String.init)
        guard parts.count >= 2 else { return suffix }

        let platform = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(platform) \(version)"
    }

    private func readableRuntimeName(from url: URL) -> String {
        var name = url.lastPathComponent
        if name.hasSuffix(".simruntime") {
            name = String(name.dropLast(".simruntime".count))
        }

        if name.contains(" ") {
            return "\(name) Runtime"
        }

        let readable = readableRuntimeIdentifier("com.apple.CoreSimulator.SimRuntime.\(name)")
        return readable.isEmpty ? "\(name) Runtime" : "\(readable) Runtime"
    }

    private func deleteContents(at url: URL, removeRoot: Bool, preferTrash: Bool) async throws {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            throw SweepError.pathNotFound(url)
        }

        do {
            if removeRoot {
                try remove(url, preferTrash: preferTrash)
            } else if isDirectory.boolValue {
                let children = try fileManager.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: []
                )
                for child in children {
                    try remove(child, preferTrash: preferTrash)
                }
            } else {
                try remove(url, preferTrash: preferTrash)
            }
        } catch let error as SweepError {
            throw error
        } catch let error as NSError {
            if error.domain == NSCocoaErrorDomain &&
                (error.code == NSFileWriteNoPermissionError || error.code == NSFileReadNoPermissionError) {
                throw SweepError.accessDenied(url)
            }
            throw SweepError.deletionFailed(url, underlying: error)
        }
    }

    private func remove(_ url: URL, preferTrash: Bool) throws {
        if preferTrash {
            do {
                var resulting: NSURL?
                try fileManager.trashItem(at: url, resultingItemURL: &resulting)
                return
            } catch {
                try fileManager.removeItem(at: url)
            }
        } else {
            try fileManager.removeItem(at: url)
        }
    }
}
