import Foundation
import FactoryKit

extension Container {
    public var router: Factory<AppRouter> {
        self {
            MainActor.assumeIsolated {
                AppRouter()
            }
        }.singleton
    }
}
