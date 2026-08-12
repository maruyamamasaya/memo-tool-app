import SwiftUI

struct RootView: View {
    @AppStorage("appearance") private var appearance = "system"

    var body: some View {
        TabView {
            HomeView().tabItem { Label("メモ", systemImage: "note.text") }
            FolderListView().tabItem { Label("フォルダ", systemImage: "folder") }
            TagListView().tabItem { Label("タグ", systemImage: "tag") }
            TrashView().tabItem { Label("ゴミ箱", systemImage: "trash") }
            SettingsView().tabItem { Label("設定", systemImage: "gearshape") }
        }
        .preferredColorScheme(appearance == "dark" ? .dark : appearance == "light" ? .light : nil)
    }
}
