import SwiftUI
import CoreNavigation
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
            case .detail(let param):
                ProductDetailView(productId: param.id)
            }
        }
        return AnyView(view)
    }
}
