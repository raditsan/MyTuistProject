import Foundation
import FactoryKit

extension Container {
    @MainActor
    public var localizationManager: Factory<LocalizationManager> {
        self { LocalizationManager.shared }.singleton
    }
}
