import Foundation

/// Error yang dapat terjadi saat berinteraksi dengan Keychain Services.
public enum KeychainError: LocalizedError, Equatable, Sendable {
    case duplicateItem
    case itemNotFound
    case dataConversionFailed
    case unhandledError(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .duplicateItem:
            return "Item sudah ada di dalam Keychain."
        case .itemNotFound:
            return "Item tidak ditemukan di dalam Keychain."
        case .dataConversionFailed:
            return "Gagal melakukan konversi string ke Data atau sebaliknya."
        case .unhandledError(let status):
            if #available(iOS 11.3, *) {
                let message = SecCopyErrorMessageString(status, nil) as String? ?? "Unknown status: \(status)"
                return "Keychain error: \(message) (Status: \(status))"
            }
            return "Keychain error dengan status: \(status)"
        }
    }
}

/// Protocol mendefinisikan kontrak penyimpanan terenkripsi berbasis hardware (Secure Enclave / Keychain),
/// ideal untuk token autentikasi (JWT, OAuth), refresh token, PIN, dan data rahasia lainnya.
public protocol SecureStorageProtocol: Sendable {
    // MARK: - Operations with SecureStorageKey Enum
    func get(forKey key: SecureStorageKey) -> String?
    func set(_ value: String?, forKey key: SecureStorageKey) throws

    func getData(forKey key: SecureStorageKey) -> Data?
    func setData(_ value: Data?, forKey key: SecureStorageKey) throws

    func hasKey(_ key: SecureStorageKey) -> Bool
    func delete(forKey key: SecureStorageKey) throws
    func deleteAll() throws

    // MARK: - Raw String Key Support (Overloads for Dynamic Keys)
    func get(forKey key: String) -> String?
    func set(_ value: String?, forKey key: String) throws

    func getData(forKey key: String) -> Data?
    func setData(_ value: Data?, forKey key: String) throws

    func hasKey(_ key: String) -> Bool
    func delete(forKey key: String) throws
}
