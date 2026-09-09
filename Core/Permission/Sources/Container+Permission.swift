import Foundation
import FactoryKit

extension Container {
    public var permission: Factory<PermissionManagerProtocol> {
        self { PermissionManager() }.singleton
    }
}
