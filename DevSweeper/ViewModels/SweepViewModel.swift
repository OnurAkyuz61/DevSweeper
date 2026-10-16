import Foundation
import Observation

@MainActor
@Observable
final class SweepViewModel {
    private let service = SweepService()

    var selectedCategory: SweepCategory = .cache {
        didSet {
            if oldValue != selectedCategory {
                selectedItemIDs.removeAll()
            }
        }
    }

    var cacheItems: [SweepItem] = []
    var simulatorItems: [SweepItem] = []
    var selectedItemIDs: Set<SweepItem.ID> = []

    var isLoading = false
    var isDeleting = false
    var deletionProgress = DeletionProgress.idle
    var deletingItemID: UUID?
    var errorMessage: String?
    var showError = false

    var confirmDeleteItem: SweepItem?
    /// Ayrı bayrak: macOS'ta optional `presenting:` dialog bazen açılmıyor.
    var showDeleteConfirmation = false
    var confirmDeleteAll = false
    var confirmDeleteSelected = false

    /// true = Çöp Kutusu (güvenli), false = kalıcı sil
    var preferTrash = true

    var items: [SweepItem] {
        switch selectedCategory {
        case .cache: return cacheItems
        case .simulators: return simulatorItems
        }
    }

    var flatItems: [SweepItem] {
        SweepItem.flatten(items)
    }

    var selectedItems: [SweepItem] {
        flatItems.filter { selectedItemIDs.contains($0.id) }
    }

    var selectedAffectsXcode: Bool {
        selectedItems.contains(where: \.affectsXcode)
    }

    var selectedByteCount: Int64 {
        selectedItems.reduce(0) { $0 + $1.byteCount }
    }

    var formattedSelectedSize: String {
        ByteCountFormatter.string(fromByteCount: selectedByteCount, countStyle: .file)
    }

    var totalByteCount: Int64 {
        items.reduce(0) { $0 + $1.byteCount }
    }

    var formattedTotalSize: String {
        ByteCountFormatter.string(fromByteCount: totalByteCount, countStyle: .file)
    }

    var canCleanAll: Bool {
        !items.isEmpty && !isLoading && !isDeleting
    }

    var canCleanSelected: Bool {
        !selectedItems.isEmpty && !isLoading && !isDeleting
    }

    var allAffectsXcode: Bool {
        flatItems.contains(where: \.affectsXcode)
    }

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let cache = service.scanCacheItems()
        async let sims = service.scanSimulatorItems()

        cacheItems = await cache
        simulatorItems = await sims
        pruneSelection()
    }

    func refreshCurrent() async {
        isLoading = true
        defer { isLoading = false }

        switch selectedCategory {
        case .cache:
            cacheItems = await service.scanCacheItems()
        case .simulators:
            simulatorItems = await service.scanSimulatorItems()
        }
        pruneSelection()
    }

    private func refreshQuietly() async {
        switch selectedCategory {
        case .cache:
            cacheItems = await service.scanCacheItems()
        case .simulators:
            simulatorItems = await service.scanSimulatorItems()
        }
        pruneSelection()
    }

    // MARK: - Delete requests

    func requestDelete(_ item: SweepItem) {
        confirmDeleteItem = item
        showDeleteConfirmation = true
    }

    func requestDeleteAll() {
        confirmDeleteAll = true
    }

    func requestDeleteSelected() {
        guard canCleanSelected else { return }
        confirmDeleteSelected = true
    }

    func cancelDeleteSingle() {
        showDeleteConfirmation = false
        confirmDeleteItem = nil
    }

    func confirmDeleteSingle() async {
        guard let item = confirmDeleteItem else {
            showDeleteConfirmation = false
            return
        }
        showDeleteConfirmation = false
        confirmDeleteItem = nil
        await performDelete([item])
    }

    func confirmDeleteAllItems() async {
        confirmDeleteAll = false
        let targets = items
        guard !targets.isEmpty else { return }
        await performDelete(targets)
    }

    func confirmDeleteSelectedItems() async {
        confirmDeleteSelected = false
        let targets = selectedItems
        guard !targets.isEmpty else { return }
        await performDelete(targets)
    }

    // MARK: - Private

    private func performDelete(_ targets: [SweepItem]) async {
        guard !targets.isEmpty else { return }

        let compact = SweepService.compactTargets(targets)
        let removedIDs = Set(SweepItem.flatten(compact).map(\.id))
            .union(compact.map(\.id))

        dropFromScreen(ids: removedIDs)

        isDeleting = true
        deletionProgress = DeletionProgress(
            currentName: compact.first?.name ?? String(localized: "Deleting…"),
            completed: 0,
            total: max(compact.count, 1),
            fractionCompleted: 0
        )
        if compact.count == 1 {
            deletingItemID = compact[0].id
        }
        defer {
            isDeleting = false
            deletingItemID = nil
            deletionProgress = .idle
        }

        do {
            try await service.deleteAll(compact, preferTrash: preferTrash) { [weak self] progress in
                guard let self else { return }
                await self.setDeletionProgress(progress)
            }
            await refreshQuietly()
        } catch {
            present(error)
            await refreshQuietly()
        }
    }

    private func setDeletionProgress(_ progress: DeletionProgress) {
        deletionProgress = progress
    }

    private func dropFromScreen(ids: Set<UUID>) {
        selectedItemIDs.subtract(ids)

        switch selectedCategory {
        case .cache:
            cacheItems = SweepItem.removing(cacheItems, ids: ids)
        case .simulators:
            simulatorItems = SweepItem.removing(simulatorItems, ids: ids)
        }
    }

    private func pruneSelection() {
        let valid = Set(flatItems.map(\.id))
        selectedItemIDs = selectedItemIDs.intersection(valid)
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
