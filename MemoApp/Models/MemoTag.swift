import Foundation
import SwiftData

@Model
final class MemoTag {
    @Attribute(.unique) var id: String
    var name: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
