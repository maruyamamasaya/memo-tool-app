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
    @State private var exportDocument: MemoArchiveDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("外観") {
                    Picker("表示", selection: $appearance) { Text("システム設定").tag("system"); Text("ライト").tag("light"); Text("ダーク").tag("dark") }
                }
                Section {
                    Button { exportAll() } label: { Label("すべてのメモをJSONで書き出す", systemImage: "square.and.arrow.up") }
                    Button { importing = true } label: { Label("JSONから読み込む", systemImage: "square.and.arrow.down") }
                } header: { Text("データ") } footer: { Text("人が確認できるJSON形式です。既存IDと重複するメモは読み飛ばします。") }
                Section("このアプリについて") { LabeledContent("保存先", value: "Firestore＋オフラインキャッシュ"); LabeledContent("バージョン", value: "1.0") }
                Section("Firebase") {
                    LabeledContent("Project ID", value: FirebaseConfigurationService.expectedProjectID)
                    LabeledContent("同期", value: sync.isConnected ? "接続済み" : "未接続")
                    if let user = auth.user { LabeledContent("アカウント", value: user.email ?? user.displayName ?? user.uid) }
                    Button("ログアウト", role: .destructive) { sync.stop(); auth.signOut() }
                }
            }
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
