import SwiftUI
import DomainProduct

public enum ProductRoute: AppRouteType {
    case list
    case detail(Product)
    case detailById(Int)

    public var destination: AppRouteDestination {
        switch self {
        case .list:
            return .product(.list)
        case .detail, .detailById:
            return .product(.detail)
        }
    }

    @MainActor @ViewBuilder
    public func makeView() -> some View {
        AppRouter.viewBuilder(.product(self))
    }

    public static var deepLinkHost: String? { "product" }

    public static func deepLinkResolve(pathComponents: [String]) -> AppRoute? {
        guard pathComponents.first == deepLinkHost else { return nil }
        let subPath = pathComponents.dropFirst().first

        if let subPath, let id = Int(subPath) {
            return .product(.detailById(id))
        }
        return .product(.list)
    }
}
