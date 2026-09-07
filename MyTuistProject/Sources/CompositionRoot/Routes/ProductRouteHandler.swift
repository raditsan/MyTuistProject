import SwiftUI
import CoreNavigation
import DomainProduct
import FeatureProduct
import FeatureProductDetail

@MainActor
public struct ProductRouteHandler {
    public static func buildView(for route: ProductRoute) -> AnyView {
        @ViewBuilder
        var view: some View {
            switch route {
            case .list:
                ProductListView()
            case .detail(let product):
                ProductDetailView(productId: product.id)
            case .detailById(let id):
                ProductDetailView(productId: id)
            }
        }
        return AnyView(view)
    }
}
