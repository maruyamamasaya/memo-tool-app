import Foundation
import SwiftData

@Model
final class MemoFolder {
    @Attribute(.unique) var id: String
    var name: String
    var colorHex: String
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, colorHex: String = "64748B", createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
