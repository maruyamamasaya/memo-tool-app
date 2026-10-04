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
