import SwiftData
import SwiftUI

struct MemoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoFolder.name) private var folders: [MemoFolder]
    @Query(sort: \MemoTag.name) private var allTags: [MemoTag]

    private let originalMemo: Memo?
    private let store = MemoStore()

    @State private var workingMemo: Memo?
    @State private var editorText: String
    @State private var folderID: UUID?
    @State private var format: String
    @State private var saveTask: Task<Void, Never>?
    @State private var saveStatus = ""
    @State private var hasChanges = false
    @FocusState private var editorFocused: Bool

    init(memo: Memo? = nil, initialFolder: MemoFolder? = nil) {
        originalMemo = memo
        _workingMemo = State(initialValue: memo)
        _editorText = State(initialValue: Self.editorText(for: memo))
        _folderID = State(initialValue: memo?.folder?.id ?? initialFolder?.id)
        _format = State(initialValue: memo?.format ?? "txt")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Text("メモ")
                    Image(systemName: "chevron.right").font(.caption2)
                    Picker("フォルダ", selection: $folderID) {
                        Text("未分類").tag(UUID?.none)
                        ForEach(folders) { Text($0.name).tag(Optional($0.id)) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("形式", selection: $format) {
                        Text(".md").tag("md")
                        Text(".txt").tag("txt")
                    }
                    .labelsHidden()
                    .fixedSize()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                ZStack(alignment: .topLeading) {
                    if editorText.isEmpty {
                        Text("タイトルを入力してください…\n\n本文を入力\n\n#タグ")
                            .font(.body.monospaced())
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $editorText)
                        .font(.body.monospaced())
                        .lineSpacing(7)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 12)
                        .focused($editorFocused)
                }

                HStack {
                    Text("1行目がタイトル、最終行の #文字がタグです")
                    Spacer()
                    Text(saveStatus)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
            }
            .memoTheme()
            .navigationTitle(originalMemo == nil ? "新規メモ" : "メモ編集中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("閉じる", action: close) }
            }
            .onAppear { editorFocused = true }
            .onChange(of: editorText) { _, _ in scheduleSave() }
            .onChange(of: folderID) { _, _ in scheduleSave() }
            .onChange(of: format) { _, _ in scheduleSave() }
            .onDisappear { saveTask?.cancel(); if hasChanges { save() } }
        }
    }

    private static func editorText(for memo: Memo?) -> String {
        guard let memo else { return "" }
        var lines = [memo.title, memo.content]
        if !memo.tags.isEmpty { lines.append(memo.tags.map { "#\($0.name)" }.joined(separator: " ")) }
        while lines.last?.isEmpty == true { lines.removeLast() }
        return lines.joined(separator: "\n")
    }

    private func scheduleSave() {
        hasChanges = true
        saveStatus = "編集中…"
        saveTask?.cancel()
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            save()
        }
    }

    private func close() {
        saveTask?.cancel()
        if hasChanges { save() }
        dismiss()
    }

    private func save() {
        let parsed = parseEditor()
        guard !parsed.title.isEmpty || !parsed.body.isEmpty else {
            saveStatus = ""
            hasChanges = false
            return
        }
        let tags = parsed.tagNames.map { name -> MemoTag in
            if let existing = allTags.first(where: { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }) { return existing }
            let tag = MemoTag(name: name)
            context.insert(tag)
            return tag
        }
        workingMemo = store.saveMemo(
            workingMemo,
            title: parsed.title.isEmpty ? "無題のメモ" : parsed.title,
            content: parsed.body,
            folder: folders.first { $0.id == folderID },
            tags: tags,
            format: parsed.format,
            in: context
        )
        if format != parsed.format { format = parsed.format }
        hasChanges = false
        saveStatus = "保存しました"
    }

    private func parseEditor() -> (title: String, body: String, tagNames: [String], format: String) {
        var lines = editorText.replacingOccurrences(of: "\r", with: "").components(separatedBy: "\n")
        var title = (lines.isEmpty ? "" : lines.removeFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        var parsedFormat = format
        if let match = title.range(of: #"\.(md|txt)$"#, options: [.regularExpression, .caseInsensitive]) {
            parsedFormat = String(title[match]).dropFirst().lowercased()
            title.removeSubrange(match)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var tagNames: [String] = []
        if let last = lines.last, last.trimmingCharacters(in: .whitespaces).hasPrefix("#") {
            lines.removeLast()
            let pieces = last.components(separatedBy: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",、")))
            for piece in pieces {
                let name = piece.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && !tagNames.contains(name) && tagNames.count < 20 { tagNames.append(name) }
            }
        }
        return (title, lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines), tagNames, parsedFormat)
    }
}
