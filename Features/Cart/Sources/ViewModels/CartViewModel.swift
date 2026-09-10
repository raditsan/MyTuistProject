import Foundation
import Combine
import CoreNavigation
import FactoryKit

@MainActor
public final class CartViewModel: ObservableObject {
    @Injected(\.router) private var router
    public let param: CartScreenParam?

    public init(param: CartScreenParam? = nil) {
        self.param = param
    }

    public func goBack() {
        router.pop()
    }
}
