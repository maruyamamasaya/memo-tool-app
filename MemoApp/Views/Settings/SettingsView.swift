import FirebaseAuth
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var auth: AuthenticationService
    @EnvironmentObject private var sync: FirebaseSyncCoordinator
    @Environment(\.modelContext) private var context
    @Query private var memos: [Memo]
    @Query private var folders: [MemoFolder]
    @Query private var tags: [MemoTag]
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("memoTheme") private var selectedTheme = MemoTheme.standard.rawValue
    @State private var exportDocument: MemoArchiveDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("テーマ") {
                    ForEach(MemoTheme.allCases) { theme in
                        Button { selectedTheme = theme.rawValue } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    if theme == .standard { Color(uiColor: .systemGray5) }
                                    else { MemoThemeBackground(theme: theme) }
                                }
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(theme.name).font(.headline).foregroundStyle(.primary)
                                    Text(theme.subtitle).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 4)
                                if selectedTheme == theme.rawValue {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(theme.accent)
                                }
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(theme.name)
                        .accessibilityAddTraits(selectedTheme == theme.rawValue ? .isSelected : [])
                    }
                }
                .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
                Section("外観") {
                    Picker("表示", selection: $appearance) { Text("システム設定").tag("system"); Text("ライト").tag("light"); Text("ダーク").tag("dark") }
                        .disabled(selectedTheme != MemoTheme.standard.rawValue)
                }
                .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
                Section {
                    Button { exportAll() } label: { Label("すべてのメモをJSONで書き出す", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("JSONから読み込む", systemImage: "square.and.arrow.down") }
                } header: { Text("データ") } footer: { Text("人が確認できるJSON形式です。既存IDと重複するメモは読み飛ばします。") }
                .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
                Section("このアプリについて") { LabeledContent("保存先", value: "Firestore＋オフラインキャッシュ"); LabeledContent("バージョン", value: "1.0") }
                .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
                Section("Firebase") {
                    LabeledContent("Project ID", value: FirebaseConfigurationService.expectedProjectID)
                    LabeledContent("同期", value: sync.isConnected ? "接続済み" : "未接続")
                    if let user = auth.user { LabeledContent("アカウント", value: user.email ?? user.displayName ?? user.uid) }
                    Button("ログアウト", role: .destructive) { sync.stop(); auth.signOut() }
                }
                .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
            }
            .memoTheme()
            .navigationTitle("設定")
            .fileExporter(isPresented: $exporting, document: exportDocument, contentType: .json, defaultFilename: "MemoApp-Backup") { result in if case .failure(let error) = result { message = error.localizedDescription }; exportDocument = nil }
            .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in importFile(result) }
            .alert("データ入出力", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK") { message = nil } } message: { Text(message ?? "") }
        }
    }
    private func exportAll() { do { exportDocument = try ImportExportService.document(memos: memos, folders: folders, tags: tags); exporting = true } catch { message = error.localizedDescription } }
    private func importFile(_ result: Result<URL, Error>) {
        do {
            let url = try result.get(); guard url.startAccessingSecurityScopedResource() else { throw CocoaError(.fileReadNoPermission) }; defer { url.stopAccessingSecurityScopedResource() }
            let count = try ImportExportService.importArchive(Data(contentsOf: url), existingMemos: memos, existingFolders: folders, existingTags: tags, into: context)
            message = "\(count)件のメモを読み込みました。"
        } catch { message = "読み込みに失敗しました: \(error.localizedDescription)" }
    }
}
