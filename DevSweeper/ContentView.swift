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
            "Öğeyi sil?",
            isPresented: Binding(
                get: { viewModel.confirmDeleteItem != nil },
                set: { if !$0 { viewModel.confirmDeleteItem = nil } }
            ),
            presenting: viewModel.confirmDeleteItem
        ) { item in
            Button("Sil", role: .destructive) {
                Task { await viewModel.confirmDeleteSingle() }
            }
            Button("İptal", role: .cancel) {
                viewModel.confirmDeleteItem = nil
            }
        } message: { item in
            Text("\"\(item.name)\" kalıcı olarak silinecek.\n\(item.path.path)")
        }
        .confirmationDialog(
            "Tümünü temizle?",
            isPresented: $viewModel.confirmDeleteAll
        ) {
            Button("Tümünü Sil", role: .destructive) {
                Task { await viewModel.confirmDeleteAllItems() }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Bu kategorideki \(viewModel.items.count) öğe silinecek (\(viewModel.formattedTotalSize)). Bu işlem geri alınamaz.")
        }
    }

    private var detailColumn: some View {
        VStack(spacing: 0) {
            SweepItemTableView(
                items: viewModel.items,
                isLoading: viewModel.isLoading,
                isDeleting: viewModel.isDeleting,
                deletingItemID: viewModel.deletingItemID,
                onClean: { viewModel.requestDelete($0) }
            )

            Divider()

            SummaryFooterView(
                itemCount: viewModel.items.count,
                totalSize: viewModel.formattedTotalSize,
                canCleanAll: viewModel.canCleanAll,
                isDeleting: viewModel.isDeleting,
                onCleanAll: { viewModel.requestDeleteAll() }
            )
        }
        .navigationTitle(viewModel.selectedCategory.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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
}

#Preview {
    ContentView()
        .frame(width: 960, height: 600)
}
