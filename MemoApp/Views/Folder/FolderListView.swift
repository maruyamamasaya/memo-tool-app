import SwiftData
import SwiftUI

struct FolderListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoFolder.name) private var folders: [MemoFolder]
    @Query private var memos: [Memo]
    @State private var editingFolder: MemoFolder?
    @State private var showNewFolder = false

    var body: some View {
        NavigationStack {
            List {
                NavigationLink { FilteredMemoList(title: "未分類", memos: memos.filter { !$0.isDeleted && $0.folder == nil }) } label: { Label("未分類", systemImage: "tray") }
                ForEach(folders) { folder in
                    NavigationLink { FilteredMemoList(title: folder.name, memos: memos.filter { !$0.isDeleted && $0.folder?.id == folder.id }, initialFolder: folder) } label: {
                        Label(folder.name, systemImage: "folder.fill")
                    }
                    .swipeActions {
                        Button { editingFolder = folder } label: { Label("名前変更", systemImage: "pencil") }.tint(.blue)
                        Button(role: .destructive) { MemoStore().deleteFolder(folder, memos: memos, in: context) } label: { Label("削除", systemImage: "trash") }
                    }
                }
            }
            .navigationTitle("フォルダ")
            .toolbar { Button { showNewFolder = true } label: { Image(systemName: "folder.badge.plus") } }
            .sheet(isPresented: $showNewFolder) { FolderEditorView() }
            .sheet(item: $editingFolder) { FolderEditorView(folder: $0) }
        }
    }
}

private struct FolderEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let folder: MemoFolder?
    @State private var name: String
    @State private var colorHex: String
    private let colors = ["64748B", "EF4444", "F97316", "F59E0B", "22C55E", "14B8A6", "3B82F6", "8B5CF6", "EC4899"]

    init(folder: MemoFolder? = nil) { self.folder = folder; _name = State(initialValue: folder?.name ?? ""); _colorHex = State(initialValue: folder?.colorHex ?? "64748B") }
    var body: some View {
        NavigationStack {
            Form {
                TextField("フォルダ名", text: $name)
                Section("カラー") { LazyVGrid(columns: [GridItem(.adaptive(minimum: 42))]) { ForEach(colors, id: \.self) { hex in Button { colorHex = hex } label: { Circle().fill(Color(hex: hex)).frame(width: 30, height: 30).overlay { if colorHex == hex { Image(systemName: "checkmark").foregroundStyle(.white) } } }.buttonStyle(.plain) } } }
            }
            .navigationTitle(folder == nil ? "フォルダ作成" : "フォルダ名変更")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存", action: save).disabled(cleanName.isEmpty) }
            }
        }
    }
    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private func save() {
        let isNew = folder == nil || folder?.isCloudBacked == false
        let saved: MemoFolder
        if let folder { folder.name = cleanName; folder.colorHex = colorHex; saved = folder }
        else { let folder = MemoFolder(name: cleanName, colorHex: colorHex); context.insert(folder); saved = folder }
        try? context.save()
        Task { if (try? await FirestoreService.shared.saveFolder(saved, isNew: isNew)) != nil { saved.isCloudBacked = true; try? context.save() } }
        dismiss()
    }
}

struct FilteredMemoList: View {
    let title: String
    let memos: [Memo]
    var initialFolder: MemoFolder? = nil
    @State private var editingMemo: Memo?
    @State private var showNew = false
    var body: some View {
        List(memos) { memo in MemoRow(memo: memo).contentShape(Rectangle()).onTapGesture { editingMemo = memo } }
            .navigationTitle(title)
            .toolbar { Button { showNew = true } label: { Image(systemName: "plus") } }
            .overlay { if memos.isEmpty { ContentUnavailableView("メモはありません", systemImage: "note.text") } }
            .sheet(item: $editingMemo) { MemoEditorView(memo: $0) }
            .sheet(isPresented: $showNew) { MemoEditorView(initialFolder: initialFolder) }
    }
}

private extension Color {
    init(hex: String) {
        var value: UInt64 = 0; Scanner(string: hex).scanHexInt64(&value)
        self.init(red: Double((value >> 16) & 255) / 255, green: Double((value >> 8) & 255) / 255, blue: Double(value & 255) / 255)
    }
}
