import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct MemoArchive: Codable {
    var version = 1
    var exportedAt = Date.now
    var folders: [FolderRecord]
    var tags: [TagRecord]
    var memos: [MemoRecord]
}

struct FolderRecord: Codable { var id: String; var name: String; var colorHex: String; var createdAt: Date }
struct TagRecord: Codable { var id: String; var name: String; var createdAt: Date }
struct MemoRecord: Codable {
    var id: String; var title: String; var content: String; var createdAt: Date; var updatedAt: Date
    var folderID: String?; var tagIDs: [String]; var tags: [String]
    var isDeleted: Bool; var deletedAt: Date?; var isPinned: Bool; var format: String
}

struct MemoArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data

    init(data: Data = Data()) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

enum ImportExportService {
    static func document(memos: [Memo], folders: [MemoFolder], tags: [MemoTag]) throws -> MemoArchiveDocument {
        let usedFolderIDs = Set(memos.compactMap { $0.folder?.id })
        let usedTagIDs = Set(memos.flatMap { $0.tags.map(\.id) })
        let archive = MemoArchive(
            folders: folders.filter { usedFolderIDs.contains($0.id) }.map { .init(id: $0.id, name: $0.name, colorHex: $0.colorHex, createdAt: $0.createdAt) },
            tags: tags.filter { usedTagIDs.contains($0.id) }.map { .init(id: $0.id, name: $0.name, createdAt: $0.createdAt) },
            memos: memos.map { memo in
                .init(id: memo.id, title: memo.title, content: memo.content, createdAt: memo.createdAt, updatedAt: memo.updatedAt, folderID: memo.folder?.id, tagIDs: memo.tags.map(\.id), tags: memo.tags.map(\.name), isDeleted: memo.isDeleted, deletedAt: memo.deletedAt, isPinned: memo.isPinned, format: memo.format)
            }
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return MemoArchiveDocument(data: try encoder.encode(archive))
    }

    @MainActor
    static func importArchive(_ data: Data, existingMemos: [Memo], existingFolders: [MemoFolder], existingTags: [MemoTag], into context: ModelContext) throws -> Int {
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let archive = try decoder.decode(MemoArchive.self, from: data)
        var folders = Dictionary(uniqueKeysWithValues: existingFolders.map { ($0.id, $0) })
        for record in archive.folders where folders[record.id] == nil {
            let folder = MemoFolder(id: record.id, name: record.name, colorHex: record.colorHex, createdAt: record.createdAt)
            context.insert(folder); folders[record.id] = folder
        }
        var tags = Dictionary(uniqueKeysWithValues: existingTags.map { ($0.id, $0) })
        for record in archive.tags where tags[record.id] == nil {
            let tag = MemoTag(id: record.id, name: record.name, createdAt: record.createdAt)
            context.insert(tag); tags[record.id] = tag
        }
        let existingIDs = Set(existingMemos.map(\.id))
        var count = 0
        for record in archive.memos where !existingIDs.contains(record.id) {
            let memoTags = record.tagIDs.compactMap { tags[$0] }
            context.insert(Memo(id: record.id, title: record.title, content: record.content, createdAt: record.createdAt, updatedAt: record.updatedAt, folder: record.folderID.flatMap { folders[$0] }, tags: memoTags, isDeleted: record.isDeleted, deletedAt: record.deletedAt, isPinned: record.isPinned, format: record.format))
            count += 1
        }
        try context.save()
        return count
    }
}
