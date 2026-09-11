import Foundation

/// Implementasi PlainStorageProtocol berbasis UserDefaults.
/// Thread-safe dan mendukung penyimpanan tipe data primitif maupun struct Codable,
/// baik menggunakan PlainStorageKey (enum) maupun String.
public final class UserDefaultsStorage: PlainStorageProtocol, @unchecked Sendable {
    public static let shared = UserDefaultsStorage()

    private let userDefaults: UserDefaults
    private let lock = NSLock()
    private let jsonEncoder = JSONEncoder()
    private let jsonDecoder = JSONDecoder()

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - PlainStorageKey Enum Support
    public func string(forKey key: PlainStorageKey) -> String? {
        string(forKey: key.rawValue)
    }

    public func set(_ value: String?, forKey key: PlainStorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func bool(forKey key: PlainStorageKey) -> Bool {
        bool(forKey: key.rawValue)
    }

    public func set(_ value: Bool, forKey key: PlainStorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func integer(forKey key: PlainStorageKey) -> Int {
        integer(forKey: key.rawValue)
    }

    public func set(_ value: Int, forKey key: PlainStorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func double(forKey key: PlainStorageKey) -> Double {
        double(forKey: key.rawValue)
    }

    public func set(_ value: Double, forKey key: PlainStorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func data(forKey key: PlainStorageKey) -> Data? {
        data(forKey: key.rawValue)
    }

    public func set(_ value: Data?, forKey key: PlainStorageKey) {
        set(value, forKey: key.rawValue)
    }

    public func object<T: Codable>(_ type: T.Type, forKey key: PlainStorageKey) -> T? {
        object(type, forKey: key.rawValue)
    }

    public func setObject<T: Codable>(_ value: T?, forKey key: PlainStorageKey) {
        setObject(value, forKey: key.rawValue)
    }

    public func hasKey(_ key: PlainStorageKey) -> Bool {
        hasKey(key.rawValue)
    }

    public func remove(forKey key: PlainStorageKey) {
        remove(forKey: key.rawValue)
    }

    // MARK: - Raw String Support
    public func string(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.string(forKey: key)
    }

    public func set(_ value: String?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    public func bool(forKey key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.bool(forKey: key)
    }

    public func set(_ value: Bool, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(value, forKey: key)
    }

    public func integer(forKey key: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.integer(forKey: key)
    }

    public func set(_ value: Int, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(value, forKey: key)
    }

    public func double(forKey key: String) -> Double {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.double(forKey: key)
    }

    public func set(_ value: Double, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.set(value, forKey: key)
    }

    public func data(forKey key: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.data(forKey: key)
    }

    public func set(_ value: Data?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    public func object<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = userDefaults.data(forKey: key) else { return nil }
        return try? jsonDecoder.decode(type, from: data)
    }

    public func setObject<T: Codable>(_ value: T?, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        if let value {
            if let encoded = try? jsonEncoder.encode(value) {
                userDefaults.set(encoded, forKey: key)
            }
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    public func hasKey(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return userDefaults.object(forKey: key) != nil
    }

    public func remove(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        userDefaults.removeObject(forKey: key)
    }

    public func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        for key in userDefaults.dictionaryRepresentation().keys {
            userDefaults.removeObject(forKey: key)
        }
        if let bundleId = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleId)
        }
    }
}
