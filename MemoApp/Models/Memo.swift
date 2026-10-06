import Foundation
import SwiftData

@Model
final class Memo {
    @Attribute(.unique) var id: UUID
    var cloudID: String
    var cloudUpdatedAt: Date? = nil
    var isCloudBacked: Bool
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
    @Attribute(originalName: "isDeleted") var isTrashed: Bool
    var deletedAt: Date?
    var isPinned: Bool
    var usage: String = "saved"
    var isConfidential: Bool = false
    var contentKind: String = "note"
    var format: String
    var folder: MemoFolder?
    @Relationship(deleteRule: .nullify) var tags: [MemoTag]

    init(
        id: UUID = UUID(), cloudID: String = UUID().uuidString, isCloudBacked: Bool = false,
        title: String = "", content: String = "",
        createdAt: Date = .now, updatedAt: Date = .now,
        folder: MemoFolder? = nil, tags: [MemoTag] = [],
        isTrashed: Bool = false, deletedAt: Date? = nil,
        isPinned: Bool = false, format: String = "txt",
        usage: String = "saved", isConfidential: Bool = false, contentKind: String = "note"
    ) {
        self.id = id
        self.cloudID = cloudID
        self.isCloudBacked = isCloudBacked
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.folder = folder
        self.tags = tags
        self.isTrashed = isTrashed
        self.deletedAt = deletedAt
        self.isPinned = isPinned
        self.format = format
        self.usage = usage
        self.isConfidential = isConfidential
        self.contentKind = contentKind
    }

    var displayTitle: String {
        let value = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "無題のメモ" : value
    }
}
