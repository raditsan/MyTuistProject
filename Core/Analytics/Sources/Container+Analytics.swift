import Foundation
import FactoryKit

extension Container {
    public var analytics: Factory<AnalyticsManagerProtocol> {
        self {
            AnalyticsManager(providers: [
                ConsoleAnalyticsProvider()
            ])
        }.singleton
    }
}
