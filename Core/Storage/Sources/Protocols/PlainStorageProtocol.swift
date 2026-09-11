import Foundation

/// Protocol mendefinisikan kontrak penyimpanan key-value standar (unencrypted / plain storage),
/// ideal untuk preferensi aplikasi, setting, cache sederhana, dan objek Codable.
public protocol PlainStorageProtocol: Sendable {
    // MARK: - Primitives with Enum Key
    func string(forKey key: PlainStorageKey) -> String?
    func set(_ value: String?, forKey key: PlainStorageKey)

    func bool(forKey key: PlainStorageKey) -> Bool
    func set(_ value: Bool, forKey key: PlainStorageKey)

    func integer(forKey key: PlainStorageKey) -> Int
    func set(_ value: Int, forKey key: PlainStorageKey)

    func double(forKey key: PlainStorageKey) -> Double
    func set(_ value: Double, forKey key: PlainStorageKey)

    func data(forKey key: PlainStorageKey) -> Data?
    func set(_ value: Data?, forKey key: PlainStorageKey)

    // MARK: - Generic Codable with Enum Key
    func object<T: Codable>(_ type: T.Type, forKey key: PlainStorageKey) -> T?
    func setObject<T: Codable>(_ value: T?, forKey key: PlainStorageKey)

    // MARK: - Management with Enum Key
    func hasKey(_ key: PlainStorageKey) -> Bool
    func remove(forKey key: PlainStorageKey)
    func removeAll()

    // MARK: - Raw String Key Support (Overloads for Dynamic Keys)
    func string(forKey key: String) -> String?
    func set(_ value: String?, forKey key: String)

    func bool(forKey key: String) -> Bool
    func set(_ value: Bool, forKey key: String)

    func integer(forKey key: String) -> Int
    func set(_ value: Int, forKey key: String)

    func double(forKey key: String) -> Double
    func set(_ value: Double, forKey key: String)

    func data(forKey key: String) -> Data?
    func set(_ value: Data?, forKey key: String)

    func object<T: Codable>(_ type: T.Type, forKey key: String) -> T?
    func setObject<T: Codable>(_ value: T?, forKey key: String)

    func hasKey(_ key: String) -> Bool
    func remove(forKey key: String)
}
