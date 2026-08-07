import Foundation
import Security

public struct KeychainConnectionStore: Sendable {
    private let service = "com.boa.devicehub.mask.ios.connection"
    private let account = "default"

    public init() {}

    public func loadHistory() throws -> ConnectionHistory {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return ConnectionHistory()
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw keychainError(operation: "load", status: status)
        }
        if let history = try? JSONDecoder().decode(ConnectionHistory.self, from: data) {
            return history
        }
        if let legacyProfile = try? JSONDecoder().decode(ConnectionProfile.self, from: data) {
            let history = ConnectionHistory(servers: [SavedServer(profile: legacyProfile)])
            try save(history)
            return history
        }
        throw DeviceHubError.protocolViolation("The saved server history is unreadable.")
    }

    public func save(_ history: ConnectionHistory) throws {
        let data = try JSONEncoder().encode(history)
        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
            ] as CFDictionary
        )
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw keychainError(operation: "update", status: updateStatus)
        }
        let attributes = baseQuery.merging([
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]) { _, new in new }
        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw keychainError(operation: "save", status: addStatus)
        }
    }

    public func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw keychainError(operation: "clear", status: status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private func keychainError(operation: String, status: OSStatus) -> DeviceHubError {
        let detail = SecCopyErrorMessageString(status, nil) as String? ?? "OSStatus \(status)"
        return .protocolViolation("Unable to \(operation) saved servers: \(detail)")
    }
}
