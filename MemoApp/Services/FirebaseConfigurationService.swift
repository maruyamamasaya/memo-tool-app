import FirebaseCore
import Foundation
import OSLog

enum FirebaseConfigurationService {
    static let expectedProjectID = "shared-memo-63202"
    static let bundleID = "maruyama.MemoApp"
    private static let logger = Logger(subsystem: bundleID, category: "FirebaseConfiguration")

    @discardableResult
    static func configure() -> Bool {
        guard FirebaseApp.app() == nil else { return true }
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let options = FirebaseOptions(contentsOfFile: path) else {
            logger.error("GoogleService-Info.plist がアプリに含まれていません")
            return false
        }
        guard options.projectID == expectedProjectID else {
            logger.error("Firebase Project ID が不一致です: \(options.projectID ?? "nil", privacy: .public)")
            return false
        }
        guard options.bundleID == Bundle.main.bundleIdentifier else {
            logger.error("Firebase Bundle ID が不一致です: \(options.bundleID, privacy: .public)")
            return false
        }
        FirebaseApp.configure(options: options)
        logger.info("Firebaseを初期化しました")
        return true
    }
}
