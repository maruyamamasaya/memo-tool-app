import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn
import OSLog
import UIKit

@MainActor
final class AuthenticationService: ObservableObject {
    @Published private(set) var user: User?
    @Published private(set) var isConfigured = false
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?
    private var authHandle: AuthStateDidChangeListenerHandle?
    private let logger = Logger(subsystem: FirebaseConfigurationService.bundleID, category: "Authentication")

    init() {
        isConfigured = FirebaseConfigurationService.configure()
        guard isConfigured else {
            errorMessage = "GoogleService-Info.plistが必要です。Firebase ConsoleでBundle ID「\(FirebaseConfigurationService.bundleID)」のiOSアプリを登録してください。"
            return
        }
        user = Auth.auth().currentUser
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    deinit { if let authHandle { Auth.auth().removeStateDidChangeListener(authHandle) } }

    func signInWithGoogle() async {
        guard isConfigured, let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Googleログイン設定を読み込めません。GoogleService-Info.plistを確認してください。"
            return
        }
        guard let presenter = Self.presentingViewController() else {
            errorMessage = "ログイン画面を表示できません。"
            return
        }
        isBusy = true; defer { isBusy = false }
        do {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)
            guard let idToken = result.user.idToken?.tokenString else { throw AuthError.missingIDToken }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: result.user.accessToken.tokenString)
            let authResult = try await Auth.auth().signIn(with: credential)
            try await Firestore.firestore().collection("users").document(authResult.user.uid).setData([
                "displayName": authResult.user.displayName ?? "名前未設定",
                "email": authResult.user.email ?? ""
            ], merge: true)
            logger.info("Googleログインに成功しました")
        } catch {
            logger.error("Googleログイン失敗: \(error.localizedDescription, privacy: .public)")
            errorMessage = Self.message(for: error, fallback: "Googleログインに失敗しました。")
        }
    }

    func signOut() {
        do { try Auth.auth().signOut(); GIDSignIn.sharedInstance.signOut() }
        catch { errorMessage = "ログアウトに失敗しました: \(error.localizedDescription)" }
    }

    func handleOpenURL(_ url: URL) { _ = GIDSignIn.sharedInstance.handle(url) }

    static func message(for error: Error, fallback: String) -> String {
        let nsError = error as NSError
        if nsError.domain == FirestoreErrorDomain, nsError.code == FirestoreErrorCode.permissionDenied.rawValue {
            return "Firestoreの権限がありません。group001のmembersに、このGoogleアカウントのUIDが登録されているか確認してください。"
        }
        if nsError.code == NSURLErrorNotConnectedToInternet { return "ネットワークに接続されていません。" }
        return "\(fallback) \(error.localizedDescription)"
    }

    private static func presentingViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first { $0.activationState == .foregroundActive }
        var controller = scene?.windows.first { $0.isKeyWindow }?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }

    private enum AuthError: LocalizedError {
        case missingIDToken
        var errorDescription: String? { "Google IDトークンを取得できませんでした。" }
    }
}
