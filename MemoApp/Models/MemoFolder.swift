import Foundation
import SwiftData

@Model
final class MemoFolder {
    @Attribute(.unique) var id: UUID
    var cloudID: String
    var isCloudBacked: Bool
    var name: String
    var colorHex: String
    var createdAt: Date

    init(id: UUID = UUID(), cloudID: String = UUID().uuidString, isCloudBacked: Bool = false, name: String, colorHex: String = "64748B", createdAt: Date = .now) {
        self.id = id
        self.cloudID = cloudID
        self.isCloudBacked = isCloudBacked
        self.name = name
        self.colorHex = colorHex
        self.createdAt = createdAt
    }
}
