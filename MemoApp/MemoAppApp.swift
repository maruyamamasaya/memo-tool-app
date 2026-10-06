//
//  MemoAppApp.swift
//  MemoApp
//
//  Created by 丸山将矢 on 2026/08/12.
//

import FirebaseCore
import SwiftUI
import SwiftData
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseConfigurationService.configure()
        return true
    }
}

@main
struct MemoAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    private let container: ModelContainer = {
        let schema = Schema([Memo.self, MemoFolder.self, MemoTag.self])
        do {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-fixture") {
                let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
                container.mainContext.insert(Memo(title: "既存の保存メモ", content: "既存データを保持"))
                container.mainContext.insert(Memo(title: "よく使うコマンド", content: "  echo hello\n\t# comment\n", isPinned: true, usage: "saved", contentKind: "command"))
                container.mainContext.insert(Memo(title: "機密テスト", content: "PRIVATE_BODY_FIXTURE", usage: "temporary", isConfidential: true))
                return container
            }
            #endif
            return try ModelContainer(for: schema)
        } catch {
            fatalError("データベースを作成できませんでした: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .modelContainer(container)
    }
}
