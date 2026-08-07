import Foundation

struct AppVersionInfo: Equatable, Sendable {
    let version: String
    let build: String

    static var current: AppVersionInfo {
        let info = Bundle.main.infoDictionary
        return AppVersionInfo(
            version: info?["CFBundleShortVersionString"] as? String ?? "Unknown",
            build: info?["CFBundleVersion"] as? String ?? "Unknown"
        )
    }
}
