import Foundation
import FactoryKit

extension Container {
    /// Factory registration untuk unencrypted key-value storage (UserDefaults).
    public var plainStorage: Factory<PlainStorageProtocol> {
        self { UserDefaultsStorage.shared }.singleton
    }

    /// Factory registration untuk hardware-encrypted secure storage (Keychain).
    public var secureStorage: Factory<SecureStorageProtocol> {
        self { KeychainStorage.shared }.singleton
    }
}
