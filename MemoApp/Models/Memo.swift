import Foundation
import SwiftData

@Model
final class Memo {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isDeleted: Bool
    var deletedAt: Date?
    var isPinned: Bool
    var format: String
    var folder: MemoFolder?
    @Relationship(deleteRule: .nullify) var tags: [MemoTag]

    init(
        id: String = UUID().uuidString, title: String = "", content: String = "",
        createdAt: Date = .now, updatedAt: Date = .now,
        folder: MemoFolder? = nil, tags: [MemoTag] = [],
        isDeleted: Bool = false, deletedAt: Date? = nil,
        isPinned: Bool = false, format: String = "txt"
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folder = folder
        self.tags = tags
        self.isDeleted = isDeleted
        self.deletedAt = deletedAt
        self.isPinned = isPinned
        self.format = format
    }

    var displayTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "無題のメモ" : value
    }
}
