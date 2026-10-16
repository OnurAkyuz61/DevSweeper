import SwiftUI

struct ContentView: View {
    @State private var viewModel = SweepViewModel()

    var body: some View {
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
        .task {
            await viewModel.loadAll()
        }
        .alert("Hata", isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button("Tamam", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .confirmationDialog(
            deletionTitle(forCount: 1),
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
            Text(deletionMessage(name: item.name, path: item.path.path, count: 1, size: item.formattedSize))
        }
        .confirmationDialog(
            deletionTitle(forCount: viewModel.selectedItems.count),
            isPresented: $viewModel.confirmDeleteSelected
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteSelectedItems() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(deletionMessage(
                name: nil,
                path: nil,
                count: viewModel.selectedItems.count,
                size: viewModel.formattedSelectedSize
            ))
        }
        .confirmationDialog(
            deletionTitle(forCount: viewModel.items.count),
            isPresented: $viewModel.confirmDeleteAll
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteAllItems() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text(deletionMessage(
                name: nil,
                path: nil,
                count: viewModel.items.count,
                size: viewModel.formattedTotalSize
            ))
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

    private func deletionTitle(forCount count: Int) -> String {
        if viewModel.preferTrash {
            return count <= 1 ? "Çöp Kutusu'na taşı?" : "Seçilenleri Çöp Kutusu'na taşı?"
        }
        return count <= 1 ? "Kalıcı sil?" : "Seçilenleri kalıcı sil?"
    }

    private func deletionMessage(name: String?, path: String?, count: Int, size: String) -> String {
        let action = viewModel.preferTrash
            ? "Çöp Kutusu'na taşınacak"
            : "kalıcı olarak silinecek"

        if let name, let path {
            return "\"\(name)\" \(action) (\(size)).\n\(path)"
        }

        return "\(count) öğe \(action) (\(size))."
    }
}

#Preview {
    ContentView()
        .frame(width: 960, height: 600)
}
