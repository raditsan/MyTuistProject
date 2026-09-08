import SwiftUI
import CoreNavigation
import DataProduct
import FactoryKit

@MainActor
public final class AppDIContainer: ObservableObject {
    public static let shared = AppDIContainer()

    public init() {
        setupDependencies()
        setupNavigation()
    }

    public func setupDependencies() {
        Container.shared.registerProductDataDependencies()
    }

    public func setupNavigation() {
        AppRouter.viewBuilder = { route in
            switch route {
            case .splash:
                return SplashRouteHandler.buildView()
            case .deeplinkFetch(let entryPoint):
                return DeeplinkRouteHandler.buildView(for: entryPoint)
            case .product(let productRoute):
                return ProductRouteHandler.buildView(for: productRoute)
            case .favorites(let favRoute):
                return FavoritesRouteHandler.buildView(for: favRoute)
            case .cart(let cartRoute):
                return CartRouteHandler.buildView(for: cartRoute)
            }
        }
    }
}
