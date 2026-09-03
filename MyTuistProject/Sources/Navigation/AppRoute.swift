import SwiftUI
import CoreNavigation
import DomainProduct
import FeatureProduct
import FeatureProductDetail

// MARK: - Global App Route Enum
public enum AppRoute: AppRouteType {
    case productList
    case productDetail(Product)
    case productDetailById(Int)

    public var destination: AppRouteDestination {
        switch self {
        case .productList:
            return .productList
        case .productDetail, .productDetailById:
            return .productDetail
        }
    }

    @MainActor @ViewBuilder
    public func makeView() -> some View {
        switch self {
        case .productList:
            AppDIContainer.shared.makeProductListView()
        case .productDetail(let product):
            AppDIContainer.shared.makeProductDetailView(productId: product.id)
        case .productDetailById(let id):
            AppDIContainer.shared.makeProductDetailView(productId: id)
        }
    }

    public static var deepLinkHost: String? { "mytuistproject" }

    public static func deepLinkResolve(pathComponents: [String]) -> (any AppRouteType)? {
        let host = pathComponents.first ?? ""
        let subComponents = Array(pathComponents.dropFirst())

        switch host {
        case "products":
            if let idString = subComponents.first, let id = Int(idString) {
                return AppRoute.productDetailById(id)
            }
            return AppRoute.productList
        default:
            return nil
        }
    }
}
