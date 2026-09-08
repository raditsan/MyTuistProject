import Foundation
import FactoryKit

extension Container {
    @MainActor
    public var localizationManager: Factory<LocalizationManagerProtocol> {
        self { LocalizationManager.shared }.singleton
    }
}
