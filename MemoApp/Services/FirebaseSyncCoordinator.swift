import FirebaseFirestore
import Foundation
import OSLog
import SwiftData

@MainActor
final class FirebaseSyncCoordinator: ObservableObject {
    @Published private(set) var isSyncing = false
    @Published private(set) var isConnected = false
    @Published var errorMessage: String?
    private var memoListener: ListenerRegistration?
    private var folderListener: ListenerRegistration?
    private var context: ModelContext?
    private var cloudFolders: [CloudFolder] = []
    private let logger = Logger(subsystem: FirebaseConfigurationService.bundleID, category: "Synchronization")

    func start(context: ModelContext) async {
        stop(); self.context = context; isSyncing = true
        do {
            try await FirestoreService.shared.verifyMembership()
            folderListener = FirestoreService.shared.listenFolders { [weak self] result in Task { @MainActor in self?.receiveFolders(result) } }
            memoListener = FirestoreService.shared.listenMemos { [weak self] result in Task { @MainActor in self?.receiveMemos(result) } }
        } catch {
            isSyncing = false; errorMessage = AuthenticationService.message(for: error, fallback: "Firebase接続に失敗しました。")
            logger.error("同期開始失敗: \(error.localizedDescription, privacy: .public)")
        }
    }

    func stop() { memoListener?.remove(); folderListener?.remove(); memoListener = nil; folderListener = nil; isConnected = false; isSyncing = false }

    private func receiveFolders(_ result: Result<[CloudFolder], Error>) {
        switch result {
        case .failure(let error): report(error, action: "フォルダ取得")
        case .success(let records):
            cloudFolders = records
            guard let context else { return }
            do {
                let local = try context.fetch(FetchDescriptor<MemoFolder>()); let ids = Set(records.map(\.id))
                for record in records {
                    if let folder = local.first(where: { $0.id == record.id }) { folder.name = record.name; folder.colorHex = record.colorHex }
                    else { context.insert(MemoFolder(id: record.id, name: record.name, colorHex: record.colorHex, createdAt: record.createdAt)) }
                }
                local.filter { !ids.contains($0.id) }.forEach(context.delete); try context.save()
            } catch { report(error, action: "フォルダキャッシュ更新") }
        }
    }

    private func receiveMemos(_ result: Result<[CloudMemo], Error>) {
        switch result {
        case .failure(let error): report(error, action: "メモ取得")
        case .success(let records):
            guard let context else { return }
            do {
                let localMemos = try context.fetch(FetchDescriptor<Memo>()); let folders = try context.fetch(FetchDescriptor<MemoFolder>()); var localTags = try context.fetch(FetchDescriptor<MemoTag>())
                let ids = Set(records.map(\.id))
                for record in records {
                    let memoTags = record.tags.map { name -> MemoTag in
                        if let tag = localTags.first(where: { $0.name == name }) { return tag }
                        let tag = MemoTag(id: "tag:\(name.lowercased())", name: name); context.insert(tag); localTags.append(tag); return tag
                    }
                    if let memo = localMemos.first(where: { $0.id == record.id }) {
                        memo.title = record.title; memo.content = record.body; memo.format = record.format; memo.folder = folders.first { $0.id == record.folderID }; memo.tags = memoTags
                        memo.isPinned = record.pinned; memo.isDeleted = record.trashed; memo.createdAt = record.createdAt; memo.updatedAt = record.updatedAt; memo.deletedAt = record.trashedAt
                    } else {
                        context.insert(Memo(id: record.id, title: record.title, content: record.body, createdAt: record.createdAt, updatedAt: record.updatedAt, folder: folders.first { $0.id == record.folderID }, tags: memoTags, isDeleted: record.trashed, deletedAt: record.trashedAt, isPinned: record.pinned, format: record.format))
                    }
                }
                localMemos.filter { !ids.contains($0.id) }.forEach(context.delete); try context.save()
                isSyncing = false; isConnected = true; errorMessage = nil
            } catch { report(error, action: "メモキャッシュ更新") }
        }
    }

    private func report(_ error: Error, action: String) {
        isSyncing = false; errorMessage = AuthenticationService.message(for: error, fallback: "\(action)に失敗しました。")
        logger.error("\(action, privacy: .public)失敗: \(error.localizedDescription, privacy: .public)")
    }
}
