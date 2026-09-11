import Foundation

/// Protocol untuk representasi kunci penyimpanan.
public protocol StorageKeyRepresentable: Sendable {
    var rawValue: String { get }
}

/// Enum kunci penyimpanan tidak terenkripsi (Plain Storage / UserDefaults).
public enum PlainStorageKey: String, CaseIterable, StorageKeyRepresentable, Sendable {
    // MARK: - App Preferences & Settings
    case isDarkMode = "app.settings.is_dark_mode"
    case selectedLanguage = "app.settings.selected_language"
    case hasCompletedOnboarding = "app.onboarding.completed"
    case pushNotificationsEnabled = "app.settings.push_notifications_enabled"

    // MARK: - User & Session Cache
    case userProfileCache = "user.profile.cache"
    case searchHistory = "search.history"
    case cartItemIds = "cart.item_ids"
    case lastSyncTimestamp = "sync.last_timestamp"

    // MARK: - For Testing
    case testString = "test.string"
    case testBool = "test.bool"
    case testInt = "test.int"
    case testDouble = "test.double"
    case testData = "test.data"
    case testObject = "test.object"
}

/// Enum kunci penyimpanan terenkripsi hardware (Secure Storage / Keychain).
public enum SecureStorageKey: String, CaseIterable, StorageKeyRepresentable, Sendable {
    // MARK: - Auth & Tokens
    case accessToken = "auth.access_token"
    case refreshToken = "auth.refresh_token"
    case idToken = "auth.id_token"

    // MARK: - Security & Credentials
    case userPin = "auth.user_pin"
    case biometricKey = "auth.biometric_key"
    case deviceSecret = "device.unique_secret"

    // MARK: - For Testing
    case testToken = "test.secure_token"
    case testSecretData = "test.secure_data"
}
