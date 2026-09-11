import XCTest
import FactoryKit
@testable import CoreStorage

private struct ProfileSettings: Codable, Equatable {
    let theme: String
    let notificationsEnabled: Bool
}

private class MockPreferences {
    @Storage(key: .isDarkMode, defaultValue: false)
    var isDarkMode: Bool

    @Storage(key: .selectedLanguage, defaultValue: "en")
    var language: String

    @Storage(key: .hasCompletedOnboarding, defaultValue: false)
    var hasCompletedOnboarding: Bool

    @Storage(key: .cartItemIds, defaultValue: 0)
    var cartCount: Int

    @Storage(key: .lastSyncTimestamp, defaultValue: 0.0)
    var lastSync: Double

    @Storage(key: .userProfileCache, defaultValue: ProfileSettings(theme: "light", notificationsEnabled: false))
    var profile: ProfileSettings

    @Storage(customKey: "dynamic_custom_string", defaultValue: "custom_default")
    var customString: String

    @Storage(customKey: "dynamic_custom_int", defaultValue: 99)
    var customInt: Int

    @Storage(customKey: "dynamic_custom_double", defaultValue: 12.34)
    var customDouble: Double

    @Storage(customKey: "dynamic_custom_bool", defaultValue: false)
    var customBool: Bool

    @SecureStorage(key: .accessToken, defaultValue: "")
    var accessToken: String

    @SecureStorage(key: .userPin, defaultValue: "")
    var userPin: String

    @SecureStorage(customKey: "dynamic_custom_secure", defaultValue: "sec_default")
    var customSecure: String
}

final class StorageWrappersTests: XCTestCase {
    private var sut: MockPreferences!

    override func setUp() {
        super.setUp()
        sut = MockPreferences()
    }

    override func tearDown() {
        UserDefaultsStorage.shared.removeAll()
        try? KeychainStorage.shared.deleteAll()
        sut = nil
        super.tearDown()
    }

    func test_storagePropertyWrapper_primitives() {
        // String
        XCTAssertEqual(sut.language, "en")
        sut.language = "id"
        XCTAssertEqual(sut.language, "id")

        // Bool
        XCTAssertFalse(sut.isDarkMode)
        sut.isDarkMode = true
        XCTAssertTrue(sut.isDarkMode)

        XCTAssertFalse(sut.hasCompletedOnboarding)
        sut.hasCompletedOnboarding = true
        XCTAssertTrue(sut.hasCompletedOnboarding)

        // Int
        XCTAssertEqual(sut.cartCount, 0)
        sut.cartCount = 7
        XCTAssertEqual(sut.cartCount, 7)

        // Double
        XCTAssertEqual(sut.lastSync, 0.0)
        sut.lastSync = 1234.56
        XCTAssertEqual(sut.lastSync, 1234.56, accuracy: 0.001)
    }

    func test_storagePropertyWrapper_customKeys() {
        // Custom String
        XCTAssertEqual(sut.customString, "custom_default")
        sut.customString = "updated_custom"
        XCTAssertEqual(sut.customString, "updated_custom")

        // Custom Int
        XCTAssertEqual(sut.customInt, 99)
        sut.customInt = 100
        XCTAssertEqual(sut.customInt, 100)

        // Custom Double
        XCTAssertEqual(sut.customDouble, 12.34, accuracy: 0.01)
        sut.customDouble = 56.78
        XCTAssertEqual(sut.customDouble, 56.78, accuracy: 0.01)

        // Custom Bool
        XCTAssertFalse(sut.customBool)
        sut.customBool = true
        XCTAssertTrue(sut.customBool)
    }

    func test_storagePropertyWrapper_codable() {
        let defaultProfile = ProfileSettings(theme: "light", notificationsEnabled: false)
        XCTAssertEqual(sut.profile, defaultProfile)

        let newProfile = ProfileSettings(theme: "dark", notificationsEnabled: true)
        sut.profile = newProfile
        XCTAssertEqual(sut.profile, newProfile)
    }

    func test_secureStoragePropertyWrapper_withEnumKeys() {
        XCTAssertEqual(sut.accessToken, "")
        sut.accessToken = "secret_jwt_token_value"
        XCTAssertEqual(sut.accessToken, "secret_jwt_token_value")

        // Setting empty string deletes item and returns defaultValue
        sut.accessToken = ""
        XCTAssertEqual(sut.accessToken, "")

        XCTAssertEqual(sut.userPin, "")
        sut.userPin = "123456"
        XCTAssertEqual(sut.userPin, "123456")
    }

    func test_secureStoragePropertyWrapper_withCustomKey() {
        XCTAssertEqual(sut.customSecure, "sec_default")
        sut.customSecure = "secret_updated"
        XCTAssertEqual(sut.customSecure, "secret_updated")

        sut.customSecure = ""
        XCTAssertEqual(sut.customSecure, "sec_default")
    }

    func test_container_dependencyInjection_plainStorage() {
        let plain = Container.shared.plainStorage()
        let secure = Container.shared.secureStorage()

        XCTAssertNotNil(plain)
        XCTAssertNotNil(secure)
    }
}
