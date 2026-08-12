//
//  MemoAppApp.swift
//  MemoApp
//
//  Created by 丸山将矢 on 2026/08/12.
//

import SwiftUI
import SwiftData

@main
struct MemoAppApp: App {
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
        }
        .modelContainer(container)
    }
}
