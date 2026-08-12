import Foundation
import SwiftData

@Model
final class MemoFolder {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, colorHex: String = "64748B", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
