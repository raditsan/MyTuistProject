import Foundation
import Security

internal struct KeychainExecutor: @unchecked Sendable {
    var copyMatching: (_ query: CFDictionary, _ result: UnsafeMutablePointer<AnyObject?>?) -> OSStatus = { SecItemCopyMatching($0, $1) }
    var add: (_ query: CFDictionary, _ result: UnsafeMutablePointer<AnyObject?>?) -> OSStatus = { SecItemAdd($0, $1) }
    var update: (_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus = { SecItemUpdate($0, $1) }
    var delete: (_ query: CFDictionary) -> OSStatus = { SecItemDelete($0) }
}

/// Implementasi SecureStorageProtocol berbasis Apple Keychain Services.
/// Thread-safe, memanfaatkan enkripsi hardware Secure Enclave dengan atribut kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly.
/// Mendukung SecureStorageKey (enum) maupun String, dengan graceful fallback untuk lingkungan unhosted Simulator Unit Test (errSecMissingEntitlement -34018).
public final class KeychainStorage: SecureStorageProtocol, @unchecked Sendable {
    public static let shared = KeychainStorage()

    private let service: String
    private let accessGroup: String?
    private let executor: KeychainExecutor
    private let lock = NSLock()

    // In-memory fallback khusus untuk unhosted unit test runner pada simulator
    private var memoryFallback: [String: Data] = [:]
    private var useMemoryFallback = false

    public init(
        service: String = Bundle.main.bundleIdentifier ?? "dev.tuist.MyTuistProject",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.executor = KeychainExecutor()
    }

    internal init(
        service: String = Bundle.main.bundleIdentifier ?? "dev.tuist.MyTuistProject",
        accessGroup: String? = nil,
        executor: KeychainExecutor
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.executor = executor
    }

    // MARK: - SecureStorageKey Enum Support
    public func get(forKey key: SecureStorageKey) -> String? {
        get(forKey: key.rawValue)
    }

    public func set(_ value: String?, forKey key: SecureStorageKey) throws {
        try set(value, forKey: key.rawValue)
    }

    public func getData(forKey key: SecureStorageKey) -> Data? {
        getData(forKey: key.rawValue)
    }

    public func setData(_ value: Data?, forKey key: SecureStorageKey) throws {
        try setData(value, forKey: key.rawValue)
    }

    public func hasKey(_ key: SecureStorageKey) -> Bool {
        hasKey(key.rawValue)
    }

    public func delete(forKey key: SecureStorageKey) throws {
        try delete(forKey: key.rawValue)
    }

    // MARK: - Raw String Operations
    public func get(forKey key: String) -> String? {
        guard let data = getData(forKey: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func set(_ value: String?, forKey key: String) throws {
        if let value {
            guard let data = value.data(using: .utf8) else {
                throw KeychainError.dataConversionFailed
            }
            try setData(data, forKey: key)
        } else {
            try delete(forKey: key)
        }
    }

    public func getData(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }

        if useMemoryFallback {
            return memoryFallback[key]
        }

        var query = baseQuery(forKey: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnData as String] = kCFBooleanTrue

        var result: AnyObject?
        let status = executor.copyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return data
        } else if status == errSecMissingEntitlement {
            useMemoryFallback = true
            return memoryFallback[key]
        }
        return nil
    }

    public func setData(_ value: Data?, forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        guard let value else {
            // Nil value = delete
            if useMemoryFallback {
                memoryFallback.removeValue(forKey: key)
                return
            }
            var deleteQuery = baseQuery(forKey: key)
            let delStatus = executor.delete(deleteQuery as CFDictionary)
            if delStatus == errSecMissingEntitlement {
                useMemoryFallback = true
                memoryFallback.removeValue(forKey: key)
            }
            return
        }

        if useMemoryFallback {
            memoryFallback[key] = value
            return
        }

        // Check if item exists in Keychain
        var query = baseQuery(forKey: key)
        let checkStatus = executor.copyMatching(query as CFDictionary, nil)

        if checkStatus == errSecSuccess {
            // Update existing item
            let attributesToUpdate: [String: Any] = [
                kSecValueData as String: value,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            ]
            let updateStatus = executor.update(query as CFDictionary, attributesToUpdate as CFDictionary)
            if updateStatus == errSecMissingEntitlement {
                useMemoryFallback = true
                memoryFallback[key] = value
            } else if updateStatus != errSecSuccess {
                throw KeychainError.unhandledError(status: updateStatus)
            }
        } else if checkStatus == errSecItemNotFound {
            // Add new item
            query[kSecValueData as String] = value
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

            let addStatus = executor.add(query as CFDictionary, nil)
            if addStatus == errSecMissingEntitlement {
                useMemoryFallback = true
                memoryFallback[key] = value
            } else if addStatus != errSecSuccess {
                throw KeychainError.unhandledError(status: addStatus)
            }
        } else if checkStatus == errSecMissingEntitlement {
            useMemoryFallback = true
            memoryFallback[key] = value
        } else {
            throw KeychainError.unhandledError(status: checkStatus)
        }
    }

    public func hasKey(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }

        if useMemoryFallback {
            return memoryFallback[key] != nil
        }

        let query = baseQuery(forKey: key)
        let status = executor.copyMatching(query as CFDictionary, nil)
        if status == errSecMissingEntitlement {
            useMemoryFallback = true
            return memoryFallback[key] != nil
        }
        return status == errSecSuccess
    }

    public func delete(forKey key: String) throws {
        lock.lock()
        defer { lock.unlock() }

        if useMemoryFallback {
            memoryFallback.removeValue(forKey: key)
            return
        }

        let query = baseQuery(forKey: key)
        let status = executor.delete(query as CFDictionary)
        if status == errSecMissingEntitlement {
            useMemoryFallback = true
            memoryFallback.removeValue(forKey: key)
        } else if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func deleteAll() throws {
        lock.lock()
        defer { lock.unlock() }

        memoryFallback.removeAll()

        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        let status = executor.delete(query as CFDictionary)
        if status == errSecMissingEntitlement {
            useMemoryFallback = true
        } else if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unhandledError(status: status)
        }
    }

    // MARK: - Private Helpers
    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        return query
    }
}
