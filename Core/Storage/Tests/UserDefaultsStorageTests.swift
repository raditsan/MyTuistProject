import XCTest
@testable import CoreStorage

private struct SampleUser: Codable, Equatable {
    let id: Int
    let name: String
    let email: String
}

final class UserDefaultsStorageTests: XCTestCase {
    private var sut: UserDefaultsStorage!
    private var userDefaults: UserDefaults!
    private let suiteName = "dev.tuist.CoreStorageTests.suite"

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        sut = UserDefaultsStorage(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        sut = nil
        userDefaults = nil
        super.tearDown()
    }

    func test_string_saveAndRetrieve_withEnumKey() {
        XCTAssertNil(sut.string(forKey: .testString))
        sut.set("Hello World", forKey: .testString)
        XCTAssertEqual(sut.string(forKey: .testString), "Hello World")

        sut.set(nil as String?, forKey: .testString)
        XCTAssertNil(sut.string(forKey: .testString))
    }

    func test_bool_saveAndRetrieve_withEnumKey() {
        XCTAssertFalse(sut.bool(forKey: .testBool))
        sut.set(true, forKey: .testBool)
        XCTAssertTrue(sut.bool(forKey: .testBool))

        sut.set(false, forKey: .testBool)
        XCTAssertFalse(sut.bool(forKey: .testBool))
    }

    func test_integer_saveAndRetrieve_withEnumKey() {
        XCTAssertEqual(sut.integer(forKey: .testInt), 0)
        sut.set(42, forKey: .testInt)
        XCTAssertEqual(sut.integer(forKey: .testInt), 42)
    }

    func test_double_saveAndRetrieve_withEnumKey() {
        XCTAssertEqual(sut.double(forKey: .testDouble), 0.0)
        sut.set(3.14159, forKey: .testDouble)
        XCTAssertEqual(sut.double(forKey: .testDouble), 3.14159, accuracy: 0.0001)
    }

    func test_data_saveAndRetrieve_withEnumKey() {
        let sampleData = "SampleData".data(using: .utf8)!
        XCTAssertNil(sut.data(forKey: .testData))
        sut.set(sampleData, forKey: .testData)
        XCTAssertEqual(sut.data(forKey: .testData), sampleData)

        sut.set(nil as Data?, forKey: .testData)
        XCTAssertNil(sut.data(forKey: .testData))
    }

    func test_codable_saveAndRetrieve_withEnumKey() {
        let user = SampleUser(id: 1, name: "Radit", email: "radit@example.com")
        XCTAssertNil(sut.object(SampleUser.self, forKey: .testObject))

        sut.setObject(user, forKey: .testObject)
        let retrieved = sut.object(SampleUser.self, forKey: .testObject)

        XCTAssertEqual(retrieved, user)
        XCTAssertEqual(retrieved?.id, 1)
        XCTAssertEqual(retrieved?.name, "Radit")

        sut.setObject(nil as SampleUser?, forKey: .testObject)
        XCTAssertNil(sut.object(SampleUser.self, forKey: .testObject))
    }

    func test_hasKey_and_remove_withEnumKey() {
        XCTAssertFalse(sut.hasKey(.testString))
        sut.set("Exists", forKey: .testString)
        XCTAssertTrue(sut.hasKey(.testString))

        sut.remove(forKey: .testString)
        XCTAssertFalse(sut.hasKey(.testString))
    }

    func test_rawStringOperations_and_removeAll() {
        let rawKey = "dynamic_user_defaults_key"
        XCTAssertNil(sut.string(forKey: rawKey))
        sut.set("some_value", forKey: rawKey)
        XCTAssertEqual(sut.string(forKey: rawKey), "some_value")
        XCTAssertTrue(sut.hasKey(rawKey))

        sut.remove(forKey: rawKey)
        XCTAssertFalse(sut.hasKey(rawKey))

        // removeAll
        sut.set("val1", forKey: "key1")
        sut.set(100, forKey: "key2")
        sut.removeAll()

        XCTAssertFalse(sut.hasKey("key1"))
        XCTAssertFalse(sut.hasKey("key2"))
    }
}

