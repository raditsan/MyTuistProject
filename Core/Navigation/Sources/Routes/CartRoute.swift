import SwiftUI

public enum CartRoute: AppRouteType {
    case list
    case detail(CartScreenParam)
    case checkout(CheckoutScreenParam)

    public var destination: AppRouteDestination {
        switch self {
        case .list:
            return .cart(.list)
        case .detail:
            return .cart(.list)
        case .checkout:
            return .cart(.checkout)
        }
    }

    @MainActor @ViewBuilder
    public func makeView() -> some View {
        AppRouter.viewBuilder(.cart(self))
    }

    public static var deepLinkHost: String? { "cart" }

    public static func deepLinkResolve(
        pathComponents: [String],
        queryParameters: [String: String] = [:]
    ) -> AppRoute? {
        guard pathComponents.first == deepLinkHost else { return nil }
        return .cart(.list)
    }
}
