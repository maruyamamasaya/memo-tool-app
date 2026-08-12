import SwiftData
import SwiftUI

struct TrashView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Memo.deletedAt, order: .reverse) private var memos: [Memo]
    @State private var purgeTarget: Memo?
    @State private var operationError: String?
    private var trashed: [Memo] { memos.filter(\.isDeleted) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(trashed) { memo in
                    MemoRow(memo: memo)
                        .swipeActions(edge: .leading) { Button { restore(memo) } label: { Label("復元", systemImage: "arrow.uturn.backward") }.tint(.green) }
                        .swipeActions(edge: .trailing) { Button(role: .destructive) { purgeTarget = memo } label: { Label("完全削除", systemImage: "trash.slash") } }
                        .contextMenu {
                            Button { restore(memo) } label: { Label("元に戻す", systemImage: "arrow.uturn.backward") }
                            Button(role: .destructive) { purgeTarget = memo } label: { Label("完全削除", systemImage: "trash.slash") }
                        }
                }
            }
            .navigationTitle("ゴミ箱")
            .overlay { if trashed.isEmpty { ContentUnavailableView("ゴミ箱は空です", systemImage: "trash") } }
            .confirmationDialog("このメモを完全に削除しますか？", isPresented: Binding(get: { purgeTarget != nil }, set: { if !$0 { purgeTarget = nil } }), titleVisibility: .visible) {
                Button("完全に削除", role: .destructive) {
                    if let purgeTarget { permanentlyDelete(purgeTarget) }
                    purgeTarget = nil
                }
                Button("キャンセル", role: .cancel) { purgeTarget = nil }
            } message: { Text("この操作は取り消せません。") }
            .alert("操作できませんでした", isPresented: Binding(get: { operationError != nil }, set: { if !$0 { operationError = nil } })) {
                Button("OK") { operationError = nil }
            } message: { Text(operationError ?? "") }
        }
    }

    private func restore(_ memo: Memo) {
        Task { @MainActor in
            do { try await MemoStore().restore(memo, in: context) }
            catch { operationError = error.localizedDescription }
        }
    }

    private func permanentlyDelete(_ memo: Memo) {
        Task { @MainActor in
            do { try await MemoStore().permanentlyDelete([memo], in: context) }
            catch { operationError = error.localizedDescription }
        }
    }
}
