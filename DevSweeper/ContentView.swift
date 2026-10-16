import SwiftUI

struct ContentView: View {
    @State private var viewModel = SweepViewModel()

    var body: some View {
        ZStack {
            NavigationSplitView {
                SidebarView(
                    selection: $viewModel.selectedCategory,
                    cacheTotal: viewModel.cacheItems.reduce(0) { $0 + $1.byteCount },
                    simulatorTotal: viewModel.simulatorItems.reduce(0) { $0 + $1.byteCount }
                )
                .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 300)
            } detail: {
                detailColumn
            }
            .disabled(viewModel.isDeleting)
            .allowsHitTesting(!viewModel.isDeleting)

            if viewModel.isDeleting {
                DeletionProgressOverlay(
                    progress: viewModel.deletionProgress,
                    preferTrash: viewModel.preferTrash
                )
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isDeleting)
        .task {
            await viewModel.loadAll()
        }
        .alert("Hata", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("Tamam", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            deletionTitle(for: viewModel.confirmDeleteItem.map { [$0] } ?? []),
            isPresented: Binding(
                get: { viewModel.confirmDeleteItem != nil },
                set: { if !$0 { viewModel.confirmDeleteItem = nil } }
            ),
            presenting: viewModel.confirmDeleteItem
        ) { item in
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteSingle() }
            }
            Button("İptal", role: .cancel) {
                viewModel.confirmDeleteItem = nil
            }
        } message: { item in
            Text(deletionMessage(for: [item]))
        }
        .confirmationDialog(
            deletionTitle(for: viewModel.selectedItems),
            isPresented: $viewModel.confirmDeleteSelected
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteSelectedItems() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(deletionMessage(for: viewModel.selectedItems))
        }
        .confirmationDialog(
            deletionTitle(for: viewModel.items),
            isPresented: $viewModel.confirmDeleteAll
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteAllItems() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(deletionMessage(for: viewModel.items, treatingAsAll: true))
        }
    }

    private var detailColumn: some View {
        VStack(spacing: 0) {
            SweepItemTableView(
                items: viewModel.items,
                selection: $viewModel.selectedItemIDs,
                isLoading: viewModel.isLoading,
                isDeleting: viewModel.isDeleting,
                deletingItemID: viewModel.deletingItemID,
                onClean: { viewModel.requestDelete($0) },
                onCleanSelected: { viewModel.requestDeleteSelected() }
            )

            Divider()

            SummaryFooterView(
                itemCount: viewModel.items.count,
                totalSize: viewModel.formattedTotalSize,
                selectedCount: viewModel.selectedItems.count,
                selectedSize: viewModel.formattedSelectedSize,
                canCleanSelected: viewModel.canCleanSelected,
                canCleanAll: viewModel.canCleanAll,
                isDeleting: viewModel.isDeleting,
                preferTrash: $viewModel.preferTrash,
                onCleanSelected: { viewModel.requestDeleteSelected() },
                onCleanAll: { viewModel.requestDeleteAll() }
            )
        }
        .navigationTitle(viewModel.selectedCategory.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                if viewModel.canCleanSelected {
                    Button {
                        viewModel.requestDeleteSelected()
                    } label: {
                        Label("Seçilenleri Temizle", systemImage: "trash")
                    }
                    .disabled(viewModel.isDeleting)
                }

                Button {
                    Task { await viewModel.refreshCurrent() }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isDeleting)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private var confirmButtonTitle: String {
        viewModel.preferTrash ? "Çöp Kutusu'na Taşı" : "Kalıcı Sil"
    }

    private func deletionTitle(for items: [SweepItem]) -> String {
        let risky = items.contains(where: \.affectsXcode)
        if risky {
            return "⚠️ Xcode uyarısı"
        }
        if viewModel.preferTrash {
            return items.count <= 1 ? "Çöp Kutusu'na taşı?" : "Seçilenleri Çöp Kutusu'na taşı?"
        }
        return items.count <= 1 ? "Kalıcı sil?" : "Seçilenleri kalıcı sil?"
    }

    private func deletionMessage(for items: [SweepItem], treatingAsAll: Bool = false) -> String {
        let action = viewModel.preferTrash
            ? "Çöp Kutusu'na taşınacak"
            : "kalıcı olarak silinecek"

        let size: String
        let count: Int
        if treatingAsAll {
            size = viewModel.formattedTotalSize
            count = items.count
        } else if items.count == 1, let item = items.first {
            var lines: [String] = [
                "\"\(item.name)\" \(action) (\(item.formattedSize)).",
                item.path.path
            ]
            if let warning = item.xcodeWarning {
                lines.append("")
                lines.append("⚠️ \(warning)")
            }
            return lines.joined(separator: "\n")
        } else {
            size = ByteCountFormatter.string(
                fromByteCount: items.reduce(0) { $0 + $1.byteCount },
                countStyle: .file
            )
            count = items.count
        }

        var text = "\(count) öğe \(action) (\(size))."
        if items.contains(where: \.affectsXcode) {
            text += "\n\n⚠️ Bu seçimde Xcode’a zarar verebilecek / yeniden indirme gerektirebilecek öğeler var. Silerseniz Xcode etkilenebilir."
        }
        return text
    }
}

#Preview {
    ContentView()
        .frame(width: 960, height: 600)
}
