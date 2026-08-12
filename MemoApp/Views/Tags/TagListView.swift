import SwiftData
import SwiftUI

struct TagListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoTag.name) private var tags: [MemoTag]
    @Query private var memos: [Memo]
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { TextField("新しいタグ", text: $newTag); Button("追加", action: addTag).disabled(cleanName.isEmpty) }
                }
                Section {
                    ForEach(tags) { tag in
                        NavigationLink { FilteredMemoList(title: "#\(tag.name)", memos: memos.filter { !$0.isDeleted && $0.tags.contains(where: { $0.id == tag.id }) }) } label: {
                            HStack { Label(tag.name, systemImage: "tag"); Spacer(); Text("\(memos.filter { !$0.isDeleted && $0.tags.contains(where: { $0.id == tag.id }) }.count)").foregroundStyle(.secondary) }
                        }
                        .swipeActions { Button(role: .destructive) { MemoStore().deleteTag(tag, memos: memos, in: context) } label: { Label("削除", systemImage: "trash") } }
                    }
                }
            }
            .navigationTitle("タグ")
        }
    }
    private var cleanName: String { newTag.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
    private func addTag() { guard !tags.contains(where: { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }) else { newTag = ""; return }; context.insert(MemoTag(name: cleanName)); try? context.save(); newTag = "" }
}
