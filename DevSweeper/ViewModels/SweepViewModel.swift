import Foundation
import Observation

@MainActor
@Observable
final class SweepViewModel {
    private let service = SweepService()

    var selectedCategory: SweepCategory = .cache
    var cacheItems: [SweepItem] = []
    var simulatorItems: [SweepItem] = []
    var isLoading = false
    var isDeleting = false
    var deletingItemID: UUID?
    var errorMessage: String?
    var showError = false
    var confirmDeleteItem: SweepItem?
    var confirmDeleteAll = false

    var items: [SweepItem] {
        switch selectedCategory {
        case .cache: return cacheItems
        case .simulators: return simulatorItems
        }
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

    // MARK: - Load

    func loadAll() async {
        isLoading = true
        defer { isLoading = false }

        async let cache = service.scanCacheItems()
        async let sims = service.scanSimulatorItems()

        cacheItems = await cache
        simulatorItems = await sims
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
    }

    // MARK: - Delete

    func requestDelete(_ item: SweepItem) {
        confirmDeleteItem = item
    }

    func requestDeleteAll() {
        confirmDeleteAll = true
    }

    func confirmDeleteSingle() async {
        guard let item = confirmDeleteItem else { return }
        confirmDeleteItem = nil
        await performDelete(item)
    }

    func confirmDeleteAllItems() async {
        confirmDeleteAll = false
        let targets = items
        guard !targets.isEmpty else { return }

        isDeleting = true
        defer { isDeleting = false }

        do {
            try await service.deleteAll(targets)
            await refreshCurrent()
        } catch {
            present(error)
            await refreshCurrent()
        }
    }

    private func performDelete(_ item: SweepItem) async {
        isDeleting = true
        deletingItemID = item.id
        defer {
            isDeleting = false
            deletingItemID = nil
        }

        do {
            try await service.delete(item)
            await refreshCurrent()
        } catch {
            present(error)
            await refreshCurrent()
        }
    }

    private func present(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}
