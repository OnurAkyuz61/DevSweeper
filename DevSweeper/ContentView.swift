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
        .alert(String(localized: "Error"), isPresented: $viewModel.showError, presenting: viewModel.errorMessage) { _ in
            Button(String(localized: "OK"), role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .alert(
            deletionTitle(for: viewModel.confirmDeleteItem.map { [$0] } ?? []),
            isPresented: $viewModel.showDeleteConfirmation
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteSingle() }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
                viewModel.cancelDeleteSingle()
            }
        } message: {
            if let item = viewModel.confirmDeleteItem {
                Text(deletionMessage(for: [item]))
            }
        }
        .alert(
            deletionTitle(for: viewModel.selectedItems),
            isPresented: $viewModel.confirmDeleteSelected
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteSelectedItems() }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(deletionMessage(for: viewModel.selectedItems))
        }
        .alert(
            deletionTitle(for: viewModel.items),
            isPresented: $viewModel.confirmDeleteAll
        ) {
            Button(confirmButtonTitle, role: .destructive) {
                Task { await viewModel.confirmDeleteAllItems() }
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
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
                        Label(String(localized: "Clean Selected"), systemImage: "trash")
                    }
                    .disabled(viewModel.isDeleting)
                }

                Button {
                    Task { await viewModel.refreshCurrent() }
                } label: {
                    Label(String(localized: "Refresh"), systemImage: "arrow.clockwise")
                }
                .disabled(viewModel.isLoading || viewModel.isDeleting)
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private var confirmButtonTitle: String {
        viewModel.preferTrash
            ? String(localized: "Move to Trash")
            : String(localized: "Delete Permanently")
    }

    private func deletionTitle(for items: [SweepItem]) -> String {
        let risky = items.contains(where: \.affectsXcode)
        if risky {
            return String(localized: "⚠️ Xcode warning")
        }
        if viewModel.preferTrash {
            return items.count <= 1
                ? String(localized: "Move to Trash?")
                : String(localized: "Move selected to Trash?")
        }
        return items.count <= 1
            ? String(localized: "Delete permanently?")
            : String(localized: "Delete selected permanently?")
    }

    private func deletionMessage(for items: [SweepItem], treatingAsAll: Bool = false) -> String {
        let action = viewModel.preferTrash
            ? String(localized: "will be moved to Trash")
            : String(localized: "will be permanently deleted")

        let size: String
        let count: Int
        if treatingAsAll {
            size = viewModel.formattedTotalSize
            count = items.count
        } else if items.count == 1, let item = items.first {
            var lines: [String] = [
                String(
                    format: String(localized: "\"%@\" %@ (%@)."),
                    item.name,
                    action,
                    item.formattedSize
                ),
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

        var text = String(
            format: String(localized: "%lld items %@ (%@)."),
            count,
            action,
            size
        )
        if items.contains(where: \.affectsXcode) {
            text += "\n\n⚠️ "
            text += String(localized: "This selection includes items that may affect Xcode or require re-downloading. Deleting them may impact Xcode.")
        }
        return text
    }
}

#Preview {
    ContentView()
        .frame(width: 960, height: 600)
}
