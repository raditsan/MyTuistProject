import Foundation
import Combine
import CoreNavigation
import FactoryKit

@MainActor
public final class CheckoutViewModel: ObservableObject {
    @Injected(\.router) private var router
    public let param: CheckoutScreenParam?

    public init(param: CheckoutScreenParam? = nil) {
        self.param = param
    }

    public func goBack() {
        router.pop()
    }
}
