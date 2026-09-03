import Foundation
import OSLog
import SwiftData

@MainActor
final class MemoStore {
    private let logger = Logger(subsystem: FirebaseConfigurationService.bundleID, category: "MemoStore")
    @discardableResult
    func saveMemo(
        _ memo: Memo?, title: String, content: String,
        folder: MemoFolder?, tags: [MemoTag], format: String,
        in context: ModelContext
    ) -> Memo {
        let now = Date.now
        let isNew = memo == nil || memo?.isCloudBacked == false
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
        Task { do { try await FirestoreService.shared.saveMemo(savedMemo, isNew: isNew); savedMemo.isCloudBacked = true; try? context.save() } catch { logger.error("Firestore保存失敗: \(error.localizedDescription, privacy: .public)") } }
        return savedMemo
    }

    func moveToTrash(_ memos: [Memo], in context: ModelContext) async throws {
        let cloudMemos = memos.filter(\.isCloudBacked)
        let now = Date.now
        let previousStates = memos.map { ($0, $0.isDeleted, $0.deletedAt, $0.updatedAt) }
        memos.forEach { $0.isDeleted = true; $0.deletedAt = now; $0.updatedAt = now }
        try context.save()
        do {
            if !cloudMemos.isEmpty { try await FirestoreService.shared.setTrash(cloudMemos, deleted: true) }
        } catch {
            previousStates.forEach { memo, isDeleted, deletedAt, updatedAt in
                memo.isDeleted = isDeleted
                memo.deletedAt = deletedAt
                memo.updatedAt = updatedAt
            }
            try? context.save()
            throw error
        }
    }

    func restore(_ memo: Memo, in context: ModelContext) async throws {
        if memo.isCloudBacked { try await FirestoreService.shared.setTrash([memo], deleted: false) }
        memo.isDeleted = false
        memo.deletedAt = nil
        memo.updatedAt = .now
        try context.save()
    }

    func permanentlyDelete(_ memos: [Memo], in context: ModelContext) async throws {
        let cloudMemos = memos.filter(\.isCloudBacked)
        if !cloudMemos.isEmpty { try await FirestoreService.shared.permanentlyDelete(cloudMemos) }
        memos.forEach(context.delete)
        try context.save()
    }

    func deleteFolder(_ folder: MemoFolder, memos: [Memo], in context: ModelContext) {
        let affected = memos.filter { $0.folder?.id == folder.id }
        if folder.isCloudBacked { Task { do { try await FirestoreService.shared.deleteFolder(folder, affectedMemos: affected.filter(\.isCloudBacked)) } catch { logger.error("フォルダ削除失敗: \(error.localizedDescription, privacy: .public)") } } }
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
