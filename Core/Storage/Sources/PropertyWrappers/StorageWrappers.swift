import Foundation

/// Property Wrapper yang memudahkan akses ke PlainStorageProtocol (UserDefaults).
/// Mirip dengan @AppStorage di SwiftUI, namun bekerja di kelas UIKit, ViewModel, dan Struct apa pun.
///
/// Contoh:
/// ```swift
/// @Storage(key: .isDarkMode, defaultValue: false)
/// var isDarkMode: Bool
///
/// @Storage(key: .userProfileCache, defaultValue: nil)
/// var userProfile: UserProfile?
/// ```
@propertyWrapper
public struct Storage<T: Codable> {
    private let key: String
    private let defaultValue: T
    private let storage: PlainStorageProtocol

    // Enum Key Initializer (Recommended)
    public init(
        key: PlainStorageKey,
        defaultValue: T,
        storage: PlainStorageProtocol = UserDefaultsStorage.shared
    ) {
        self.key = key.rawValue
        self.defaultValue = defaultValue
        self.storage = storage
    }

    // Raw String Initializer (Fallback for dynamic keys)
    public init(
        customKey: String,
        defaultValue: T,
        storage: PlainStorageProtocol = UserDefaultsStorage.shared
    ) {
        self.key = customKey
        self.defaultValue = defaultValue
        self.storage = storage
    }

    public var wrappedValue: T {
        get {
            // Check primitive types first for optimal performance
            if T.self == String.self {
                return (storage.string(forKey: key) as? T) ?? defaultValue
            } else if T.self == Bool.self {
                if storage.hasKey(key) {
                    return (storage.bool(forKey: key) as? T) ?? defaultValue
                }
                return defaultValue
            } else if T.self == Int.self {
                if storage.hasKey(key) {
                    return (storage.integer(forKey: key) as? T) ?? defaultValue
                }
                return defaultValue
            } else if T.self == Double.self {
                if storage.hasKey(key) {
                    return (storage.double(forKey: key) as? T) ?? defaultValue
                }
                return defaultValue
            }

            // Fallback to generic Codable
            return storage.object(T.self, forKey: key) ?? defaultValue
        }
        set {
            if let str = newValue as? String {
                storage.set(str, forKey: key)
            } else if let b = newValue as? Bool {
                storage.set(b, forKey: key)
            } else if let i = newValue as? Int {
                storage.set(i, forKey: key)
            } else if let d = newValue as? Double {
                storage.set(d, forKey: key)
            } else {
                storage.setObject(newValue, forKey: key)
            }
        }
    }
}

/// Property Wrapper untuk penyimpanan terenkripsi di Keychain.
///
/// Contoh:
/// ```swift
/// @SecureStorage(key: .accessToken, defaultValue: "")
/// var accessToken: String
/// ```
@propertyWrapper
public struct SecureStorage {
    private let key: String
    private let defaultValue: String
    private let storage: SecureStorageProtocol

    // Enum Key Initializer (Recommended)
    public init(
        key: SecureStorageKey,
        defaultValue: String = "",
        storage: SecureStorageProtocol = KeychainStorage.shared
    ) {
        self.key = key.rawValue
        self.defaultValue = defaultValue
        self.storage = storage
    }

    // Raw String Initializer (Fallback for dynamic keys)
    public init(
        customKey: String,
        defaultValue: String = "",
        storage: SecureStorageProtocol = KeychainStorage.shared
    ) {
        self.key = customKey
        self.defaultValue = defaultValue
        self.storage = storage
    }

    public var wrappedValue: String {
        get {
            storage.get(forKey: key) ?? defaultValue
        }
        set {
            if newValue.isEmpty {
                try? storage.delete(forKey: key)
            } else {
                try? storage.set(newValue, forKey: key)
            }
        }
    }
}
