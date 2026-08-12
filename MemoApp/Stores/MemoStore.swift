import Foundation
import OSLog
import SwiftData

@MainActor
final class MemoStore {
    private let logger = Logger(subsystem: FirebaseConfigurationService.bundleID, category: "MemoStore")
    func saveMemo(
        _ memo: Memo?, title: String, content: String,
        folder: MemoFolder?, tags: [MemoTag], format: String,
        in context: ModelContext
    ) {
        let now = Date.now
        let isNew = memo == nil
        let savedMemo: Memo
        if let memo {
            memo.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            memo.content = content
            memo.folder = folder
            memo.tags = tags
            memo.format = format
            memo.updatedAt = now
            savedMemo = memo
        } else {
            let memo = Memo(title: title.trimmingCharacters(in: .whitespacesAndNewlines), content: content, updatedAt: now, folder: folder, tags: tags, format: format)
            context.insert(memo); savedMemo = memo
        }
        try? context.save()
        Task { do { try await FirestoreService.shared.saveMemo(savedMemo, isNew: isNew) } catch { logger.error("Firestore保存失敗: \(error.localizedDescription, privacy: .public)") } }
    }

    func moveToTrash(_ memos: [Memo], in context: ModelContext) {
        let now = Date.now
        memos.forEach { $0.isDeleted = true; $0.deletedAt = now; $0.updatedAt = now }
        try? context.save()
        Task { do { try await FirestoreService.shared.setTrash(memos, deleted: true) } catch { logger.error("ゴミ箱移動失敗: \(error.localizedDescription, privacy: .public)") } }
    }

    func restore(_ memo: Memo, in context: ModelContext) {
        memo.isDeleted = false
        memo.deletedAt = nil
        memo.updatedAt = .now
        try? context.save()
        Task { do { try await FirestoreService.shared.setTrash([memo], deleted: false) } catch { logger.error("復元失敗: \(error.localizedDescription, privacy: .public)") } }
    }

    func permanentlyDelete(_ memos: [Memo], in context: ModelContext) {
        Task { do { try await FirestoreService.shared.permanentlyDelete(memos) } catch { logger.error("完全削除失敗: \(error.localizedDescription, privacy: .public)") } }
        memos.forEach(context.delete)
        try? context.save()
    }

    func deleteFolder(_ folder: MemoFolder, memos: [Memo], in context: ModelContext) {
        let affected = memos.filter { $0.folder?.id == folder.id }
        Task { do { try await FirestoreService.shared.deleteFolder(folder, affectedMemos: affected) } catch { logger.error("フォルダ削除失敗: \(error.localizedDescription, privacy: .public)") } }
        affected.forEach { $0.folder = nil; $0.updatedAt = .now }
        context.delete(folder)
        try? context.save()
    }

    func deleteTag(_ tag: MemoTag, memos: [Memo], in context: ModelContext) {
        memos.forEach { memo in memo.tags.removeAll { $0.id == tag.id } }
        context.delete(tag)
        try? context.save()
    }
}
