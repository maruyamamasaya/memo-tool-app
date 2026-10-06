import SwiftData
import SwiftUI

struct MemoEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \MemoFolder.name) private var folders: [MemoFolder]
    @Query(sort: \MemoTag.name) private var allTags: [MemoTag]
    private let originalMemo: Memo?
    @State private var workingMemo: Memo?
    @State private var editorText: String
    @State private var rawTitle: String
    @State private var rawTags: String
    @State private var rawMode: Bool
    @State private var folderID: UUID?
    @State private var format: String
    @State private var usage: String
    @State private var confidential: Bool
    @State private var contentKind: String
    @State private var debounce: Task<Void, Never>?
    @State private var saveStatus = ""
    @State private var hasChanges = false
    @State private var saving = false
    @State private var revision = 0
    @FocusState private var editorFocused: Bool

    init(memo: Memo? = nil, initialFolder: MemoFolder? = nil, initialUsage: String = "temporary") {
        originalMemo = memo
                _workingMemo = State(initialValue: memo)
        _rawMode = State(initialValue: true)
        _rawTitle = State(initialValue: memo?.title ?? "")
        _rawTags = State(initialValue: memo?.tags.map(\.name).joined(separator: " ") ?? "")
        _editorText = State(initialValue: memo?.content ?? "")
        _folderID = State(initialValue: memo?.folder?.id ?? initialFolder?.id)
        _format = State(initialValue: memo?.format ?? "txt")
        _usage = State(initialValue: memo?.usage ?? initialUsage)
        _confidential = State(initialValue: memo?.isConfidential ?? false)
        _contentKind = State(initialValue: memo?.contentKind ?? "note")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Picker("用途", selection: $usage) { Text("一時").tag("temporary"); Text("保存").tag("saved") }
                    Picker("内容", selection: $contentKind) {
                        ForEach(["note", "prompt", "command", "code"], id: \.self) { Text(MemoInput.kindLabels[$0]!).tag($0) }
                    }
                    Toggle("機密", isOn: $confidential).fixedSize()
                }.font(.caption).padding(.horizontal)
                HStack {
                    Picker("フォルダ", selection: $folderID) {
                        Text("未分類").tag(UUID?.none)
                        ForEach(folders) { Text($0.name).tag(Optional($0.id)) }
                    }
                    Picker("形式", selection: $format) { Text(".md").tag("md"); Text(".txt").tag("txt") }
                    Toggle("本文そのまま", isOn: $rawMode).fixedSize()
                }.font(.caption).padding(.horizontal)
                if rawMode {
                    TextField("タイトル（省略可）", text: $rawTitle).padding(.horizontal)
                    TextField("タグ（スペース区切り）", text: $rawTags).font(.caption).padding(.horizontal)
                }
                TextEditor(text: $editorText).font(.body.monospaced()).lineSpacing(5)
                    .scrollContentBackground(.hidden).padding(.horizontal, 12).focused($editorFocused)
                    .accessibilityLabel("メモ本文")
                HStack {
                    Text(rawMode ? "改行・空白・#をそのまま保存" : "1行目はタイトル、最終行は #タグ")
                    Spacer()
                    Text(saveStatus).accessibilityIdentifier("save-status")
                }.font(.caption2).foregroundStyle(.secondary).padding(12)
            }
            .memoTheme().navigationTitle(originalMemo == nil ? "新規メモ" : "メモ編集中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(saving ? "保存中…" : "閉じる") { Task { if !hasChanges { dismiss() } else if await save() { dismiss() } } }.disabled(saving)
                }
                ToolbarItem(placement: .bottomBar) {
                    Button("保存 / 再試行") { Task { _ = await save() } }.disabled(saving)
                }
            }
            .interactiveDismissDisabled(hasChanges || saving)
            .onAppear { editorFocused = true }
            .onChange(of: editorText) { _, _ in scheduleSave() }
            .onChange(of: rawTitle) { _, _ in scheduleSave() }
            .onChange(of: rawTags) { _, _ in scheduleSave() }
            .onChange(of: folderID) { _, _ in scheduleSave() }
            .onChange(of: format) { _, _ in scheduleSave() }
            .onChange(of: usage) { _, _ in scheduleSave() }
            .onChange(of: confidential) { _, _ in scheduleSave() }
            .onChange(of: contentKind) { _, _ in scheduleSave() }
            .onChange(of: rawMode) { _, raw in
                if raw { let p = MemoInput.parse(editorText, format: format); rawTitle = p.title; rawTags = p.tags.joined(separator: " "); editorText = p.body }
                else { editorText = [rawTitle, editorText] .joined(separator: "\n") + (rawTags.isEmpty ? "" : "\n" + MemoInput.parseTags(rawTags).map { "#\($0)" }.joined(separator: " ")) }
                scheduleSave()
            }
            .onDisappear { debounce?.cancel() }
        }
    }

    private static func combined(_ memo: Memo?) -> String {
        guard let memo else { return "" }
        return [memo.title, memo.content].joined(separator: "\n") + (memo.tags.isEmpty ? "" : "\n" + memo.tags.map { "#\($0.name)" }.joined(separator: " "))
    }
    private func scheduleSave() {
        hasChanges = true; revision += 1; saveStatus = "編集中…"; debounce?.cancel()
        debounce = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
            _ = await save()
        }
    }
    @MainActor private func save() async -> Bool {
        guard !saving else { return false }
        let parsed = rawMode ? (title: String(rawTitle.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120)), body: editorText, tags: MemoInput.parseTags(rawTags), format: format) : MemoInput.parse(editorText, format: format)
        guard !parsed.title.isEmpty || !parsed.body.isEmpty else { hasChanges = false; return true }
        let currentRevision = revision
        saving = true; saveStatus = "保存中…"
        defer { saving = false }
        do {
            let tags = parsed.tags.map { name -> MemoTag in
                if let existing = allTags.first(where: { $0.name == name }) { return existing }
                let tag = MemoTag(name: name); context.insert(tag); return tag
            }
            let memo = try MemoStore().saveMemo(workingMemo, title: parsed.title.isEmpty ? "無題のメモ" : parsed.title, content: parsed.body, folder: folders.first { $0.id == folderID }, tags: tags, format: parsed.format, usage: usage, isConfidential: confidential, contentKind: contentKind, in: context)
            workingMemo = memo
            try await FirestoreService.shared.saveMemo(memo, isNew: !memo.isCloudBacked)
            memo.isCloudBacked = true; try context.save()
            hasChanges = revision != currentRevision
            saveStatus = hasChanges ? "編集中…" : "保存済み"
            if hasChanges { scheduleSave() }
            return !hasChanges
        } catch { hasChanges = true; saveStatus = "同期失敗 · 再試行"; return false }
    }
}
