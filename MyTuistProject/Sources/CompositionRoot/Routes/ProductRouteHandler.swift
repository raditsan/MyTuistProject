import SwiftUI
import CoreNavigation
import DomainProduct
import FeatureProduct
import FeatureProductDetail

@MainActor
public struct ProductRouteHandler {
    public static func buildView(for route: ProductRoute) -> AnyView {
        switch route {
        case .list:
            return AnyView(ProductListView())
        case .detail(let product):
            return AnyView(ProductDetailView(productId: product.id))
        case .detailById(let id):
            return AnyView(ProductDetailView(productId: id))
        }
    }
}
