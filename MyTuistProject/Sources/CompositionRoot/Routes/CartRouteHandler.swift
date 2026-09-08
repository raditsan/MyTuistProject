import SwiftUI
import CoreNavigation
import FeatureCart

@MainActor
public struct CartRouteHandler {
    public static func buildView(for route: CartRoute) -> AnyView {
        @ViewBuilder
        var view: some View {
            switch route {
            case .list:
                CartView()
            case .detail(let param):
                CartView(param: param)
            case .checkout(let param):
                CheckoutView(param: param)
            }
        }
        return AnyView(view)
    }
}
