import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.updatedAt, order: .reverse) private var memos: [Memo]
    @Query(sort: \MemoFolder.name) private var folders: [MemoFolder]
    @Query(sort: \MemoTag.name) private var tags: [MemoTag]
    private let store = MemoStore()
    @State private var search = ""
    @State private var selected = Set<UUID>()
    @State private var editMode: EditMode = .inactive
    @State private var editingMemo: Memo?
    @State private var showNewMemo = false
    @State private var exportDocument: MemoArchiveDocument?
    @State private var exporting = false
    @State private var operationError: String?

    private var visibleMemos: [Memo] {
        memos.filter { !$0.isDeleted && (search.isEmpty || [$0.title, $0.content].contains { $0.localizedCaseInsensitiveContains(search) } || $0.tags.contains { $0.name.localizedCaseInsensitiveContains(search) }) }
            .sorted { $0.isPinned != $1.isPinned ? $0.isPinned : $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            Group {
                if visibleMemos.isEmpty { ContentUnavailableView(search.isEmpty ? "メモはありません" : "見つかりません", systemImage: search.isEmpty ? "note.text.badge.plus" : "magnifyingglass", description: Text(search.isEmpty ? "右上の＋から最初のメモを作成できます。" : "検索語を変えてみてください。")) }
                else {
                    List(selection: $selected) {
                        ForEach(visibleMemos) { memo in
                            MemoRow(memo: memo).tag(memo.id).contentShape(Rectangle()).onTapGesture { if editMode == .inactive { editingMemo = memo } }
                                .swipeActions(edge: .trailing) { Button(role: .destructive) { trash([memo]) } label: { Label("ゴミ箱", systemImage: "trash") } }
                                .contextMenu {
                                    Button { memo.isPinned.toggle(); memo.updatedAt = .now; try? context.save(); Task { try? await FirestoreService.shared.saveMemo(memo, isNew: !memo.isCloudBacked) } } label: { Label(memo.isPinned ? "ピンを外す" : "ピン留め", systemImage: "pin") }
                                    Button(role: .destructive) { trash([memo]) } label: { Label("ゴミ箱へ移動", systemImage: "trash") }
                                }
                        }
                    }
                }
            }
            .navigationTitle("メモ")
            .searchable(text: $search, prompt: "タイトル、本文、タグを検索")
            .environment(\.editMode, $editMode)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if editMode == .active {
                        Button { exportSelected() } label: { Image(systemName: "square.and.arrow.up") }.disabled(selected.isEmpty)
                        Button(role: .destructive) { trashSelected() } label: { Image(systemName: "trash") }.disabled(selected.isEmpty)
                    } else { Button { showNewMemo = true } label: { Image(systemName: "plus") } }
                }
            }
            .safeAreaInset(edge: .bottom) { if editMode == .active { Text("\(selected.count)件を選択中").font(.footnote).foregroundStyle(.secondary).padding(8) } }
            .sheet(isPresented: $showNewMemo) { MemoEditorView() }
            .sheet(item: $editingMemo) { MemoEditorView(memo: $0) }
            .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "MemoApp-Export") { _ in exportDocument = nil }
            .alert("ゴミ箱へ移動できませんでした", isPresented: Binding(get: { operationError != nil }, set: { if !$0 { operationError = nil } })) {
                Button("OK") { operationError = nil }
            } message: { Text(operationError ?? "") }
        }
    }

    private func trashSelected() { trash(memos.filter { selected.contains($0.id) }) }
    private func trash(_ targets: [Memo]) {
        guard !targets.isEmpty else { return }
        Task { @MainActor in
            do {
                try await store.moveToTrash(targets, in: context)
                selected.subtract(targets.map(\.id))
                if selected.isEmpty { editMode = .inactive }
            } catch {
                operationError = error.localizedDescription
            }
        }
    }
    private func exportSelected() {
        exportDocument = try? ImportExportService.document(memos: memos.filter { selected.contains($0.id) }, folders: folders, tags: tags)
        exporting = exportDocument != nil
    }
}
