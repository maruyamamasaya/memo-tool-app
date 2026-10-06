import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.updatedAt, order: .reverse) private var memos: [Memo]
    private let store = MemoStore()
    @State private var search = ""
    @State private var category = "all"
    @State private var selectedMemo: Memo?
    @State private var showNewMemo = false
    @State private var operationError: String?
    @State private var trashInProgress = false

    private var visibleMemos: [Memo] {
        memos.filter { !$0.isTrashed && (category == "all" || (category == "pinned" ? $0.isPinned : category == "confidential" ? $0.isConfidential : $0.usage == category)) && (search.isEmpty || [$0.title, $0.isConfidential ? "" : $0.content].contains { $0.localizedCaseInsensitiveContains(search) } || $0.tags.contains { $0.name.localizedCaseInsensitiveContains(search) }) }
            .sorted { $0.isPinned != $1.isPinned ? $0.isPinned : $0.updatedAt > $1.updatedAt }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("メモの区分", selection: $category) {
                    Text("すべて").tag("all"); Text("一時").tag("temporary"); Text("保存").tag("saved"); Text("固定").tag("pinned"); Text("機密").tag("confidential")
                }.pickerStyle(.segmented).padding(.horizontal)
                Group {
                if visibleMemos.isEmpty { ContentUnavailableView(search.isEmpty ? "メモはありません" : "見つかりません", systemImage: search.isEmpty ? "note.text.badge.plus" : "magnifyingglass", description: Text(search.isEmpty ? "右上の＋から最初のメモを作成できます。" : "検索語を変えてみてください。")) }
                else {
                    List {
                        ForEach(visibleMemos) { memo in
                            MemoRow(memo: memo).contentShape(Rectangle()).onTapGesture { selectedMemo = memo }
                                .swipeActions(edge: .trailing) { Button(role: .destructive) { trash([memo]) } label: { Label("ゴミ箱", systemImage: "trash") } }
                                .contextMenu {
                                    Button { Task { do { try await store.setPinned(memo, pinned: !memo.isPinned, in: context) } catch { operationError = error.localizedDescription } } } label: { Label(memo.isPinned ? "ピンを外す" : "ピン留め", systemImage: "pin") }
                                    Button(role: .destructive) { trash([memo]) } label: { Label("ゴミ箱へ移動", systemImage: "trash") }
                                }
                        }
                    }
                }
            }
            }
            .overlay { if trashInProgress { ProgressView("ゴミ箱へ移動中…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
            .disabled(trashInProgress)
            .memoTheme()
            .navigationTitle("メモ")
            .searchable(text: $search, prompt: "タイトル、本文、タグを検索")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { showNewMemo = true } label: { Image(systemName: "plus") } }
            }
            .sheet(isPresented: $showNewMemo) { MemoEditorView(initialUsage: category == "saved" ? "saved" : "temporary") }
            .sheet(item: $selectedMemo) { MemoReadOnlyView(memo: $0) }
            .alert("ゴミ箱へ移動できませんでした", isPresented: Binding(get: { operationError != nil }, set: { if !$0 { operationError = nil } })) {
                Button("OK") { operationError = nil }
            } message: { Text(operationError ?? "") }
        }
    }

    private func trash(_ targets: [Memo]) {
        guard !targets.isEmpty, !trashInProgress else { return }
        trashInProgress = true
        Task { @MainActor in
            defer { trashInProgress = false }
            do {
                try await store.moveToTrash(targets, in: context)
            } catch {
                operationError = AuthenticationService.message(for: error, fallback: "ゴミ箱への移動に失敗しました。")
            }
        }
    }
}
