import SwiftData
import SwiftUI

struct MemoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoFolder.name) private var folders: [MemoFolder]
    @Query(sort: \MemoTag.name) private var allTags: [MemoTag]
    let memo: Memo?
    private let store = MemoStore()

    @State private var title: String
    @State private var content: String
    @State private var folderID: UUID?
    @State private var selectedTagIDs: Set<UUID>
    @State private var format: String
    @State private var showTags = false

    init(memo: Memo? = nil, initialFolder: MemoFolder? = nil) {
        self.memo = memo
        _title = State(initialValue: memo?.title ?? "")
        _content = State(initialValue: memo?.content ?? "")
        _folderID = State(initialValue: memo?.folder?.id ?? initialFolder?.id)
        _selectedTagIDs = State(initialValue: Set(memo?.tags.map(\.id) ?? []))
        _format = State(initialValue: memo?.format ?? "txt")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("タイトル（未入力でも保存できます）", text: $title)
                        .font(.title3.weight(.semibold))
                    TextEditor(text: $content).frame(minHeight: 320, alignment: .top)
                }
                Section("整理") {
                    Picker("フォルダ", selection: $folderID) {
                        Text("未分類").tag(UUID?.none)
                        ForEach(folders) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Button { showTags = true } label: {
                        LabeledContent("タグ", value: selectedTagIDs.isEmpty ? "なし" : "\(selectedTagIDs.count)個")
                    }.foregroundStyle(.primary)
                    Picker("形式", selection: $format) {
                        Text("テキスト (.txt)").tag("txt")
                        Text("Markdown (.md)").tag("md")
                    }
                }
            }
            .navigationTitle(memo == nil ? "新規メモ" : "メモを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("閉じる") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).fontWeight(.semibold) }
            }
            .sheet(isPresented: $showTags) { TagPickerView(selectedIDs: $selectedTagIDs) }
        }
    }

    private func save() {
        store.saveMemo(memo, title: title, content: content, folder: folders.first { $0.id == folderID }, tags: allTags.filter { selectedTagIDs.contains($0.id) }, format: format, in: context)
        dismiss()
    }
}

private struct TagPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoTag.name) private var tags: [MemoTag]
    @Binding var selectedIDs: Set<UUID>
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack { TextField("新しいタグ", text: $newTag); Button("追加", action: add).disabled(cleanName.isEmpty) }
                }
                Section("既存のタグ") {
                    ForEach(tags) { tag in
                        Button { toggle(tag.id) } label: {
                            HStack { Text("#\(tag.name)"); Spacer(); if selectedIDs.contains(tag.id) { Image(systemName: "checkmark") } }
                        }.foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("タグを選択")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完了") { dismiss() } } }
        }
    }
    private var cleanName: String { newTag.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines) }
    private func add() {
        guard selectedIDs.count < 20 else { return }
        if let existing = tags.first(where: { $0.name.localizedCaseInsensitiveCompare(cleanName) == .orderedSame }) { selectedIDs.insert(existing.id) }
        else { let tag = MemoTag(name: cleanName); context.insert(tag); selectedIDs.insert(tag.id); try? context.save() }
        newTag = ""
    }
    private func toggle(_ id: UUID) { if selectedIDs.contains(id) { selectedIDs.remove(id) } else if selectedIDs.count < 20 { selectedIDs.insert(id) } }
}
