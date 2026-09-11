import Foundation
import FactoryKit

extension Container {
    /// Factory registration untuk NotificationServiceProtocol (Singleton).
    public var notificationService: Factory<NotificationServiceProtocol> {
        self { NotificationService.shared }.singleton
    }
}
