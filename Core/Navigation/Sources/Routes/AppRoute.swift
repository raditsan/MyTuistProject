import SwiftUI
import DomainProduct

// MARK: - Global App Route Enum
public enum AppRoute: AppRouteType {
    case splash
    case productList
    case productDetail(Product)
    case productDetailById(Int)
    case product(ProductRoute)

    public var destination: AppRouteDestination {
        switch self {
        case .splash:
            return .splash
        case .productList:
            return .productList
        case .productDetail, .productDetailById:
            return .productDetail
        case .product(let subRoute):
            return subRoute.destination
        }
    }

    @MainActor @ViewBuilder
    public func makeView() -> some View {
        AppRouter.viewBuilder(self)
    }

    public var sheetConfiguration: SheetConfiguration? {
        nil
    }

    // MARK: - Deep Link
    public static var deepLinkHost: String? { nil }

    public static func deepLinkResolve(pathComponents: [String]) -> AppRoute? {
        let host = pathComponents.first ?? ""
        let subComponents = Array(pathComponents.dropFirst())

        switch host {
        case "products":
            if let idString = subComponents.first, let id = Int(idString) {
                return .productDetailById(id)
            }
            return .productList
        default:
            return nil
        }
    }
}
