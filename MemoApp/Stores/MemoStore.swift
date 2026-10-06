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
        usage: String, isConfidential: Bool, contentKind: String,
        in context: ModelContext
    ) throws -> Memo {
        let now = Date.now
        let savedMemo: Memo
        if let memo {
            memo.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            memo.content = content
            memo.folder = folder
            memo.tags = tags
            memo.format = format
            memo.usage = usage; memo.isConfidential = isConfidential; memo.contentKind = contentKind
            memo.updatedAt = now
            savedMemo = memo
        } else {
            let memo = Memo(title: title.trimmingCharacters(in: .whitespacesAndNewlines), content: content, updatedAt: now, folder: folder, tags: tags, format: format, usage: usage, isConfidential: isConfidential, contentKind: contentKind)
            context.insert(memo); savedMemo = memo
        }
        try context.save()
        return savedMemo
    }

    func setPinned(_ memo: Memo, pinned: Bool, in context: ModelContext) async throws {
        if memo.isCloudBacked { try await FirestoreService.shared.setPinned(memo, pinned: pinned) }
        memo.isPinned = pinned; memo.updatedAt = .now; try context.save()

    }

    func moveToTrash(_ memos: [Memo], in context: ModelContext) async throws {
        let cloudMemos = memos.filter(\.isCloudBacked)
        // Confirm the cloud write before changing the local cache. A failed write
        // leaves the memo in its original state instead of removing and restoring it.
        if !cloudMemos.isEmpty {
            try await FirestoreService.shared.setTrash(cloudMemos, deleted: true)
        }
        let now = Date.now
        memos.forEach { $0.isTrashed = true; $0.deletedAt = now; $0.updatedAt = now }
        try context.save()
    }

    func restore(_ memo: Memo, in context: ModelContext) async throws {
        if memo.isCloudBacked { try await FirestoreService.shared.setTrash([memo], deleted: false) }
        memo.isTrashed = false
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
