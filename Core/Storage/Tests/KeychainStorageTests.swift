import XCTest
import Security
@testable import CoreStorage

final class KeychainStorageTests: XCTestCase {
    private var sut: KeychainStorage!
    private let testService = "dev.tuist.CoreStorageTests.Keychain"

    override func setUp() {
        super.setUp()
        sut = KeychainStorage(service: testService)
        try? sut.deleteAll()
    }

    override func tearDown() {
        try? sut.deleteAll()
        sut = nil
        super.tearDown()
    }

    func test_keychainError_descriptionsAndEquality() {
        let dup = KeychainError.duplicateItem
        let notFound = KeychainError.itemNotFound
        let convFailed = KeychainError.dataConversionFailed
        let unhandled = KeychainError.unhandledError(status: errSecAuthFailed)

        XCTAssertNotNil(dup.errorDescription)
        XCTAssertTrue(dup.errorDescription!.contains("sudah ada"))

        XCTAssertNotNil(notFound.errorDescription)
        XCTAssertTrue(notFound.errorDescription!.contains("tidak ditemukan"))

        XCTAssertNotNil(convFailed.errorDescription)
        XCTAssertTrue(convFailed.errorDescription!.contains("Gagal melakukan konversi"))

        XCTAssertNotNil(unhandled.errorDescription)
        XCTAssertTrue(unhandled.errorDescription!.contains("Keychain error"))

        XCTAssertEqual(dup, KeychainError.duplicateItem)
        XCTAssertNotEqual(dup, notFound)
        XCTAssertEqual(unhandled, KeychainError.unhandledError(status: errSecAuthFailed))
        XCTAssertNotEqual(unhandled, KeychainError.unhandledError(status: errSecParam))
    }

    func test_string_saveRetrieveUpdateDelete_withEnumKey() throws {
        let key: SecureStorageKey = .testToken

        // 1. Initial should be nil
        XCTAssertNil(sut.get(forKey: key))
        XCTAssertFalse(sut.hasKey(key))

        // 2. Save
        try sut.set("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9", forKey: key)
        XCTAssertEqual(sut.get(forKey: key), "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        XCTAssertTrue(sut.hasKey(key))

        // 3. Update
        try sut.set("new_updated_token_value", forKey: key)
        XCTAssertEqual(sut.get(forKey: key), "new_updated_token_value")

        // 4. Delete
        try sut.delete(forKey: key)
        XCTAssertNil(sut.get(forKey: key))
        XCTAssertFalse(sut.hasKey(key))
    }

    func test_rawData_saveAndRetrieve_withEnumKey() throws {
        let key: SecureStorageKey = .testSecretData
        let data = "MySecretDataPayload".data(using: .utf8)!

        try sut.setData(data, forKey: key)
        let retrieved = sut.getData(forKey: key)

        XCTAssertEqual(retrieved, data)

        // Setting nil should delete
        try sut.setData(nil, forKey: key)
        XCTAssertNil(sut.getData(forKey: key))
    }

    func test_deleteAll_clearsAllKeysForService() throws {
        try sut.set("token1", forKey: .accessToken)
        try sut.set("token2", forKey: .refreshToken)

        XCTAssertTrue(sut.hasKey(.accessToken))
        XCTAssertTrue(sut.hasKey(.refreshToken))

        try sut.deleteAll()

        XCTAssertFalse(sut.hasKey(.accessToken))
        XCTAssertFalse(sut.hasKey(.refreshToken))
    }

    func test_rawStringOperations_and_nilHandling() throws {
        let rawKey = "dynamic_api_secret_key"
        XCTAssertNil(sut.get(forKey: rawKey))
        XCTAssertFalse(sut.hasKey(rawKey))

        try sut.set("my_api_secret_value", forKey: rawKey)
        XCTAssertEqual(sut.get(forKey: rawKey), "my_api_secret_value")
        XCTAssertTrue(sut.hasKey(rawKey))

        // Setting nil as string deletes key
        try sut.set(nil as String?, forKey: rawKey)
        XCTAssertNil(sut.get(forKey: rawKey))
        XCTAssertFalse(sut.hasKey(rawKey))
    }

    // MARK: - Testing KeychainExecutor Mock (Exercises 100% of Keychain C API Branches)
    func test_keychainExecutor_successLifecycle() throws {
        final class MockStorageBox: @unchecked Sendable {
            var items: [String: Data] = [:]
        }
        let box = MockStorageBox()

        var executor = KeychainExecutor()
        executor.copyMatching = { query, result in
            let dict = query as NSDictionary
            guard let account = dict[kSecAttrAccount as String] as? String else {
                return errSecParam
            }
            if let data = box.items[account] {
                if let returnData = dict[kSecReturnData as String] as? Bool, returnData {
                    result?.pointee = data as AnyObject
                }
                return errSecSuccess
            }
            return errSecItemNotFound
        }
        executor.add = { query, _ in
            let dict = query as NSDictionary
            guard let account = dict[kSecAttrAccount as String] as? String,
                  let data = dict[kSecValueData as String] as? Data else {
                return errSecParam
            }
            box.items[account] = data
            return errSecSuccess
        }
        executor.update = { query, attributes in
            let queryDict = query as NSDictionary
            let attrDict = attributes as NSDictionary
            guard let account = queryDict[kSecAttrAccount as String] as? String,
                  let data = attrDict[kSecValueData as String] as? Data else {
                return errSecParam
            }
            box.items[account] = data
            return errSecSuccess
        }
        executor.delete = { query in
            let dict = query as NSDictionary
            if let account = dict[kSecAttrAccount as String] as? String {
                box.items.removeValue(forKey: account)
                return errSecSuccess
            }
            // If deleting all items
            box.items.removeAll()
            return errSecSuccess
        }

        let mockSut = KeychainStorage(service: "test.mock.service", accessGroup: "group.test", executor: executor)

        // 1. Initial get is nil
        XCTAssertNil(mockSut.get(forKey: .accessToken))
        XCTAssertFalse(mockSut.hasKey(.accessToken))

        // 2. Add new item
        try mockSut.set("initial_token", forKey: .accessToken)
        XCTAssertEqual(mockSut.get(forKey: .accessToken), "initial_token")
        XCTAssertTrue(mockSut.hasKey(.accessToken))

        // 3. Update existing item
        try mockSut.set("updated_token", forKey: .accessToken)
        XCTAssertEqual(mockSut.get(forKey: .accessToken), "updated_token")

        // 4. Set nil data deletes item
        try mockSut.setData(nil, forKey: SecureStorageKey.accessToken.rawValue)
        XCTAssertNil(mockSut.get(forKey: .accessToken))
        XCTAssertFalse(mockSut.hasKey(.accessToken))

        // 5. Delete specific key
        try mockSut.set("some_token", forKey: .refreshToken)
        XCTAssertTrue(mockSut.hasKey(.refreshToken))
        try mockSut.delete(forKey: .refreshToken)
        XCTAssertFalse(mockSut.hasKey(.refreshToken))

        // 6. Delete all
        try mockSut.set("val1", forKey: .accessToken)
        try mockSut.set("val2", forKey: .refreshToken)
        try mockSut.deleteAll()
        XCTAssertNil(mockSut.get(forKey: .accessToken))
        XCTAssertNil(mockSut.get(forKey: .refreshToken))
    }

    func test_keychainExecutor_errorHandling() {
        // Error on Add
        var addErrorExecutor = KeychainExecutor()
        addErrorExecutor.copyMatching = { _, _ in errSecItemNotFound }
        addErrorExecutor.add = { _, _ in errSecAuthFailed }

        let addErrorSut = KeychainStorage(service: "test", executor: addErrorExecutor)
        XCTAssertThrowsError(try addErrorSut.set("fail", forKey: .accessToken)) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.unhandledError(status: errSecAuthFailed))
        }

        // Error on Update
        var updateErrorExecutor = KeychainExecutor()
        updateErrorExecutor.copyMatching = { _, _ in errSecSuccess }
        updateErrorExecutor.update = { _, _ in errSecAuthFailed }

        let updateErrorSut = KeychainStorage(service: "test", executor: updateErrorExecutor)
        XCTAssertThrowsError(try updateErrorSut.set("fail", forKey: .accessToken)) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.unhandledError(status: errSecAuthFailed))
        }

        // Error on Delete
        var deleteErrorExecutor = KeychainExecutor()
        deleteErrorExecutor.delete = { _ in errSecAuthFailed }

        let deleteErrorSut = KeychainStorage(service: "test", executor: deleteErrorExecutor)
        XCTAssertThrowsError(try deleteErrorSut.delete(forKey: .accessToken)) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.unhandledError(status: errSecAuthFailed))
        }

        // ItemNotFound on Delete is ignored (graceful)
        var notFoundDeleteExecutor = KeychainExecutor()
        notFoundDeleteExecutor.delete = { _ in errSecItemNotFound }
        let notFoundDeleteSut = KeychainStorage(service: "test", executor: notFoundDeleteExecutor)
        XCTAssertNoThrow(try notFoundDeleteSut.delete(forKey: .accessToken))

        // Error on DeleteAll
        var deleteAllErrorExecutor = KeychainExecutor()
        deleteAllErrorExecutor.delete = { _ in errSecAuthFailed }
        let deleteAllErrorSut = KeychainStorage(service: "test", executor: deleteAllErrorExecutor)
        XCTAssertThrowsError(try deleteAllErrorSut.deleteAll()) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.unhandledError(status: errSecAuthFailed))
        }

        // Error on CopyMatching during setData check
        var copyErrorExecutor = KeychainExecutor()
        copyErrorExecutor.copyMatching = { _, _ in errSecParam }
        let copyErrorSut = KeychainStorage(service: "test", executor: copyErrorExecutor)
        XCTAssertThrowsError(try copyErrorSut.setData("data".data(using: .utf8)!, forKey: "testKey")) { error in
            XCTAssertEqual(error as? KeychainError, KeychainError.unhandledError(status: errSecParam))
        }
    }
}
