import Foundation
import SwiftData

@MainActor
final class MemoStore {
    func saveMemo(
        _ memo: Memo?, title: String, content: String,
        folder: MemoFolder?, tags: [MemoTag], format: String,
        in context: ModelContext
    ) {
        let now = Date.now
        if let memo {
            memo.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            memo.content = content
            memo.folder = folder
            memo.tags = tags
            memo.format = format
            memo.updatedAt = now
        } else {
            context.insert(Memo(title: title.trimmingCharacters(in: .whitespacesAndNewlines), content: content, updatedAt: now, folder: folder, tags: tags, format: format))
        }
        try? context.save()
    }

    func moveToTrash(_ memos: [Memo], in context: ModelContext) {
        let now = Date.now
        memos.forEach { $0.isDeleted = true; $0.deletedAt = now; $0.updatedAt = now }
        try? context.save()
    }

    func restore(_ memo: Memo, in context: ModelContext) {
        memo.isDeleted = false
        memo.deletedAt = nil
        memo.updatedAt = .now
        try? context.save()
    }

    func permanentlyDelete(_ memos: [Memo], in context: ModelContext) {
        memos.forEach(context.delete)
        try? context.save()
    }

    func deleteFolder(_ folder: MemoFolder, memos: [Memo], in context: ModelContext) {
        memos.filter { $0.folder?.id == folder.id }.forEach { $0.folder = nil; $0.updatedAt = .now }
        context.delete(folder)
        try? context.save()
    }

    func deleteTag(_ tag: MemoTag, memos: [Memo], in context: ModelContext) {
        memos.forEach { memo in memo.tags.removeAll { $0.id == tag.id } }
        context.delete(tag)
        try? context.save()
    }
}
