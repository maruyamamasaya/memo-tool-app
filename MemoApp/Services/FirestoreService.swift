import FirebaseAuth
import FirebaseFirestore
import Foundation
import OSLog

final class FirestoreService: @unchecked Sendable {
    static let shared = FirestoreService()
    static let groupID = "group001"
    private let logger = Logger(subsystem: FirebaseConfigurationService.bundleID, category: "Firestore")
    private var db: Firestore { Firestore.firestore() }

    func verifyMembership() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { throw CloudError.notAuthenticated }
        let snapshot = try await db.collection("groups").document(Self.groupID).getDocument()
        guard let members = snapshot.data()?["members"] as? [String], members.contains(uid) else { throw CloudError.notGroupMember }
    }

    func listenMemos(_ completion: @escaping @Sendable (Result<[CloudMemo], Error>) -> Void) -> ListenerRegistration {
        db.collection("memos").whereField("groupId", isEqualTo: Self.groupID).addSnapshotListener { snapshot, error in
            if let error { completion(.failure(error)); return }
            completion(.success(snapshot?.documents.compactMap(CloudMemo.init) ?? []))
        }
    }

    func listenFolders(_ completion: @escaping @Sendable (Result<[CloudFolder], Error>) -> Void) -> ListenerRegistration {
        db.collection("folders").whereField("groupId", isEqualTo: Self.groupID).addSnapshotListener { snapshot, error in
            if let error { completion(.failure(error)); return }
            completion(.success(snapshot?.documents.compactMap(CloudFolder.init) ?? []))
        }
    }

    func saveMemo(_ memo: Memo, isNew: Bool) async throws {
        guard let user = Auth.auth().currentUser else { throw CloudError.notAuthenticated }
        let title = memo.displayTitle
        var data: [String: Any] = [
            "title": title, "body": memo.content, "type": "text", "format": memo.format,
            "folderId": memo.folder.map { $0.cloudID as Any } ?? NSNull(), "tags": memo.tags.map(\.name), "pinned": memo.isPinned,
            "trashed": memo.isDeleted, "trashedAt": memo.deletedAt.map { Timestamp(date: $0) as Any } ?? NSNull(),
            "updatedBy": user.uid, "updatedByName": user.displayName ?? "名前未設定", "updatedAt": FieldValue.serverTimestamp()
        ]
        let reference = db.collection("memos").document(memo.cloudID)
        if isNew {
            data.merge(["groupId": Self.groupID, "lastOpenedAt": FieldValue.serverTimestamp(), "createdBy": user.uid,
                        "createdByName": user.displayName ?? "名前未設定", "createdAt": FieldValue.serverTimestamp()]) { _, new in new }
            try await reference.setData(data)
        } else { try await reference.updateData(data) }
    }

    func setTrash(_ memos: [Memo], deleted: Bool) async throws {
        guard let user = Auth.auth().currentUser else { throw CloudError.notAuthenticated }
        let batch = db.batch()
        for memo in memos {
            batch.updateData([
                "trashed": deleted,
                "trashedAt": deleted ? FieldValue.serverTimestamp() : NSNull(),
                "updatedBy": user.uid,
                "updatedByName": user.displayName ?? "名前未設定",
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: db.collection("memos").document(memo.cloudID))
        }
        try await batch.commit()
    }

    func permanentlyDelete(_ memos: [Memo]) async throws {
        let batch = db.batch(); memos.forEach { batch.deleteDocument(db.collection("memos").document($0.cloudID)) }; try await batch.commit()
    }

    func saveFolder(_ folder: MemoFolder, isNew: Bool) async throws {
        guard let user = Auth.auth().currentUser else { throw CloudError.notAuthenticated }
        let ref = db.collection("folders").document(folder.cloudID)
        if isNew { try await ref.setData(["groupId": Self.groupID, "name": folder.name, "color": "#\(folder.colorHex)", "createdBy": user.uid, "createdAt": FieldValue.serverTimestamp()]) }
        else { try await ref.updateData(["name": folder.name, "color": "#\(folder.colorHex)"]) }
    }

    func deleteFolder(_ folder: MemoFolder, affectedMemos: [Memo]) async throws {
        guard let user = Auth.auth().currentUser else { throw CloudError.notAuthenticated }
        let batch = db.batch()
        affectedMemos.forEach { batch.updateData(["folderId": NSNull(), "updatedBy": user.uid, "updatedByName": user.displayName ?? "名前未設定", "updatedAt": FieldValue.serverTimestamp()], forDocument: db.collection("memos").document($0.cloudID)) }
        batch.deleteDocument(db.collection("folders").document(folder.cloudID)); try await batch.commit()
    }

    enum CloudError: LocalizedError { case notAuthenticated, notGroupMember
        var errorDescription: String? { self == .notAuthenticated ? "ログインが必要です。" : "group001を利用する権限がありません。" }
    }
}

struct CloudMemo: Sendable {
    let id, title, body, format: String; let folderID: String?; let tags: [String]
    let pinned, trashed: Bool; let createdAt, updatedAt: Date; let trashedAt: Date?
    nonisolated init?(_ document: QueryDocumentSnapshot) {
        let data = document.data(); id = document.documentID; title = data["title"] as? String ?? ""; body = data["body"] as? String ?? ""
        format = ["md", "txt"].contains(data["format"] as? String ?? "") ? data["format"] as! String : "txt"
        folderID = data["folderId"] as? String; tags = data["tags"] as? [String] ?? []; pinned = data["pinned"] as? Bool ?? false; trashed = data["trashed"] as? Bool ?? false
        createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now; updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? createdAt; trashedAt = (data["trashedAt"] as? Timestamp)?.dateValue()
    }
}

struct CloudFolder: Sendable {
    let id, name, colorHex: String; let createdAt: Date
    nonisolated init?(_ document: QueryDocumentSnapshot) { let data = document.data(); id = document.documentID; guard let name = data["name"] as? String else { return nil }; self.name = name; colorHex = (data["color"] as? String ?? "#64748B").replacingOccurrences(of: "#", with: ""); createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? .now }
}
