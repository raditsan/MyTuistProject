import SwiftUI
import CoreNavigation
import DomainProduct
import DataProduct
import FeatureSplash
import FeatureDeeplinkLoader
import FeatureProduct
import FeatureProductDetail
import FeatureFavorites
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
                return AnyView(SplashView())
            case .deeplinkFetch(let entryPoint):
                return AnyView(DeeplinkLoaderView(entryPoint: entryPoint))
            case .product(let productRoute):
                switch productRoute {
                case .list:
                    return AnyView(ProductListView())
                case .detail(let product):
                    return AnyView(ProductDetailView(productId: product.id))
                case .detailById(let id):
                    return AnyView(ProductDetailView(productId: id))
                }
            case .favorites(let favRoute):
                switch favRoute {
                case .list:
                    return AnyView(FavoritesView())
                }
            }
        }
    }
}
