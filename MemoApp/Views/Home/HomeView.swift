import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.updatedAt, order: .reverse) private var memos: [Memo]
    private let store = MemoStore()
    @State private var search = ""
    @State private var editingMemo: Memo?
    @State private var showNewMemo = false
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
                    List {
                        ForEach(visibleMemos) { memo in
                            MemoRow(memo: memo).contentShape(Rectangle()).onTapGesture { editingMemo = memo }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { showNewMemo = true } label: { Image(systemName: "plus") } }
            }
            .sheet(isPresented: $showNewMemo) { MemoEditorView() }
            .sheet(item: $editingMemo) { MemoEditorView(memo: $0) }
            .alert("ゴミ箱へ移動できませんでした", isPresented: Binding(get: { operationError != nil }, set: { if !$0 { operationError = nil } })) {
                Button("OK") { operationError = nil }
            } message: { Text(operationError ?? "") }
        }
    }

    private func trash(_ targets: [Memo]) {
        guard !targets.isEmpty else { return }
        Task { @MainActor in
            do {
                try await store.moveToTrash(targets, in: context)
            } catch {
                operationError = error.localizedDescription
            }
        }
    }
}
