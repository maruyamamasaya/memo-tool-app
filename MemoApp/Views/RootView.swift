import FirebaseAuth
import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("memoTheme") private var selectedTheme = MemoTheme.standard.rawValue
    @StateObject private var auth = AuthenticationService()
    @StateObject private var sync = FirebaseSyncCoordinator()

    var body: some View {
        Group {
            if !auth.isConfigured { FirebaseSetupRequiredView(message: auth.errorMessage) }
            else if auth.user == nil { LoginView() }
            else {
                TabView {
                    HomeView().tabItem { Label("メモ", systemImage: "note.text") }
                    FolderListView().tabItem { Label("フォルダ", systemImage: "folder") }
                    TagListView().tabItem { Label("タグ", systemImage: "tag") }
                    TrashView().tabItem { Label("ゴミ箱", systemImage: "trash") }
                    SettingsView().tabItem { Label("設定", systemImage: "gearshape") }
                }
                .overlay(alignment: .top) { if sync.isSyncing { ProgressView("Firebaseと同期中…").padding(10).background(.regularMaterial, in: Capsule()).padding(.top, 6) } }
                .task(id: auth.user?.uid) { await sync.start(context: context) }
            }
        }
        .memoTheme()
        .tint((MemoTheme(rawValue: selectedTheme) ?? .standard).accent)
        .environmentObject(auth).environmentObject(sync)
        .preferredColorScheme(selectedTheme != MemoTheme.standard.rawValue ? .dark : appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
        .onOpenURL { auth.handleOpenURL($0) }
        .alert("Firebase", isPresented: Binding(get: { auth.errorMessage != nil || sync.errorMessage != nil }, set: { if !$0 { auth.errorMessage = nil; sync.errorMessage = nil } })) {
            Button("OK") { auth.errorMessage = nil; sync.errorMessage = nil }
        } message: { Text(auth.errorMessage ?? sync.errorMessage ?? "") }
    }
}

private struct LoginView: View {
    @EnvironmentObject private var auth: AuthenticationService
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "note.text").font(.system(size: 64)).foregroundStyle(.tint)
            VStack(spacing: 8) { Text("MemoApp").font(.largeTitle.bold()); Text("Web版と同じメモを表示するには、group001に登録済みのGoogleアカウントでログインしてください。").multilineTextAlignment(.center).foregroundStyle(.secondary) }
            Button { Task { await auth.signInWithGoogle() } } label: { Label(auth.isBusy ? "ログイン中…" : "Googleでログイン", systemImage: "person.crop.circle.badge.checkmark").frame(maxWidth: 280) }.buttonStyle(.borderedProminent).controlSize(.large).disabled(auth.isBusy)
        }.padding(32)
    }
}

private struct FirebaseSetupRequiredView: View {
    let message: String?
    var body: some View {
        ContentUnavailableView("Firebase設定が必要です", systemImage: "externaldrive.badge.exclamationmark", description: Text(message ?? "GoogleService-Info.plistを追加してください。"))
    }
}
