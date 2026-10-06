import UIKit
import UniformTypeIdentifiers
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

final class ShareViewController: UIViewController {
    private let text = UITextView()
    private let titleField = UITextField()
    private let usage = UISegmentedControl(items: ["一時", "保存"])
    private let confidential = UISwitch()
    private let status = UILabel()
    private var saving = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        titleField.placeholder = "タイトル（省略可）"; titleField.borderStyle = .roundedRect
        text.font = .monospacedSystemFont(ofSize: 16, weight: .regular)
        text.accessibilityLabel = "共有する本文"
        usage.selectedSegmentIndex = 0
        status.numberOfLines = 0; status.font = .preferredFont(forTextStyle: .caption1)
        let privateRow = UIStackView(arrangedSubviews: [UILabel(), confidential])
        (privateRow.arrangedSubviews[0] as? UILabel)?.text = "機密（目印）"
        let save = UIButton(type: .system); save.setTitle("メモに保存", for: .normal); save.addTarget(self, action: #selector(send), for: .touchUpInside)
        let cancel = UIButton(type: .system); cancel.setTitle("キャンセル", for: .normal); cancel.addTarget(self, action: #selector(close), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [cancel, titleField, usage, privateRow, text, status, save])
        stack.axis = .vertical; stack.spacing = 12; stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16), stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), stack.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -16), text.heightAnchor.constraint(greaterThanOrEqualToConstant: 100)])
        Task { await loadAttachments() }
    }

    @MainActor private func loadAttachments() async {
        var parts: [String] = []
        for item in extensionContext?.inputItems as? [NSExtensionItem] ?? [] {
            if let content = item.attributedContentText?.string, !content.isEmpty { parts.append(content) }
            for provider in item.attachments ?? [] {
                let type = provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) ? UTType.url.identifier : UTType.plainText.identifier
                guard provider.hasItemConformingToTypeIdentifier(type) else { continue }
                do {
                    let value = try await provider.loadItem(forTypeIdentifier: type)
                    let part = (value as? URL)?.absoluteString ?? (value as? String) ?? (value as? Data).flatMap { String(data: $0, encoding: .utf8) }
                    if let part, !parts.contains(part) { parts.append(part) }
                } catch { status.text = "共有内容を読み込めませんでした。本文を入力できます。" }
            }
        }
        text.text = parts.joined(separator: "\n\n")
    }
    @objc private func close() { guard !saving else { return }; extensionContext?.completeRequest(returningItems: nil) }
    @objc private func send() {
        guard !saving, !text.text.isEmpty else { status.text = "本文を入力してください。"; return }
        guard text.text.count <= 50000 else { status.text = "本文は50,000文字までです。"; return }
        let body = text.text ?? "", title = String((titleField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        let selectedUsage = usage.selectedSegmentIndex == 0 ? "temporary" : "saved", isConfidential = confidential.isOn
        saving = true; status.text = "保存中…"
        Task { @MainActor in
            defer { saving = false }
            do {
                if FirebaseApp.app() == nil {
                    guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"), let options = FirebaseOptions(contentsOfFile: path), options.projectID == "shared-memo-63202" else { throw ShareError.setup }
                    FirebaseApp.configure(options: options)
                }
                guard let group = Bundle.main.object(forInfoDictionaryKey: "MemoAuthAccessGroup") as? String else { throw ShareError.setup }
                try Auth.auth().useUserAccessGroup(group)
                guard let user = Auth.auth().currentUser else { throw ShareError.login }
                let db = Firestore.firestore(), membership = try await db.collection("groups").document("group001").getDocument()
                guard (membership.data()?["members"] as? [String])?.contains(user.uid) == true else { throw ShareError.membership }
                try await db.collection("memos").document().setData([
                    "groupId": "group001", "title": title.isEmpty ? "無題のメモ" : title, "body": body,
                    "type": "text", "format": "txt", "folderId": NSNull(), "tags": [String](), "pinned": false,
                    "usage": selectedUsage, "confidential": isConfidential, "contentKind": "note",
                    "trashed": false, "trashedAt": NSNull(), "createdBy": user.uid, "createdByName": user.displayName ?? "名前未設定",
                    "updatedBy": user.uid, "updatedByName": user.displayName ?? "名前未設定",
                    "createdAt": FieldValue.serverTimestamp(), "updatedAt": FieldValue.serverTimestamp()
                ])
                status.text = "保存済み"; extensionContext?.completeRequest(returningItems: nil)
            } catch { status.text = (error as? ShareError)?.errorDescription ?? "保存できませんでした。接続を確認して再試行してください。" }
        }
    }
    private enum ShareError: LocalizedError {
        case setup, login, membership
        var errorDescription: String? {
            switch self { case .setup: "共有の設定を読み込めませんでした。"; case .login: "MemoAppを開いてGoogleログインしてから再度共有してください。"; case .membership: "このグループを利用する権限がありません。" }
        }
    }
}
