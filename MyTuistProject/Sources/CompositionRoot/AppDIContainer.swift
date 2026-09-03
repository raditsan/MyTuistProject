import SwiftUI
import CoreNavigation
import DomainProduct
import DataProduct
import FeatureProduct
import FeatureProductDetail
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
            case .productList:
                return AnyView(ProductListView())
            case .productDetail(let product):
                return AnyView(ProductDetailView(productId: product.id))
            case .productDetailById(let id):
                return AnyView(ProductDetailView(productId: id))
            }
        }
    }
}
