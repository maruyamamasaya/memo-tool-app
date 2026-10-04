import Foundation
import SwiftData

// Compile this executable with the app's actual Models/*.swift files.
@main
struct MemoPersistenceRegression {
    @MainActor
    static func main() throws {
        let storeURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let schema = Schema([Memo.self, MemoFolder.self, MemoTag.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(url: storeURL))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        #if LEGACY_SCHEMA
        let folder = MemoFolder(name: "検証フォルダ")
        let tag = MemoTag(name: "検証タグ")
        context.insert(folder)
        context.insert(tag)
        context.insert(Memo(title: "移行テスト", content: "本文を保持", folder: folder, tags: [tag]))
        try context.save()
        print("PASS: legacy database created")
        #else
        let memo = try context.fetch(FetchDescriptor<Memo>()).first!
        precondition(memo.title == "移行テスト" && memo.content == "本文を保持")
        precondition(memo.folder?.name == "検証フォルダ" && memo.tags.first?.name == "検証タグ")
        precondition(!memo.isTrashed)
        memo.isTrashed = true
        memo.deletedAt = .now
        try context.save()
        precondition(memo.isTrashed, "Saving must preserve the trash flag")
        let reloaded = try ModelContext(container).fetch(FetchDescriptor<Memo>()).first!
        precondition(reloaded.isTrashed && reloaded.deletedAt != nil)
        memo.isTrashed = false
        memo.deletedAt = nil
        try context.save()
        let restored = try ModelContext(container).fetch(FetchDescriptor<Memo>()).first!
        precondition(!restored.isTrashed && restored.deletedAt == nil)
        let date = Date.now.addingTimeInterval(-3)
        let text = date.formatted(.relative(presentation: .named).locale(Locale(identifier: "ja_JP")))
        precondition(text.contains("秒") && !text.contains("ago"))
        print("PASS: existing database migration, title/body/folder/tags preserved, trash save/reload, restore save/reload, Japanese date (\(text))")
        #endif
    }
}
