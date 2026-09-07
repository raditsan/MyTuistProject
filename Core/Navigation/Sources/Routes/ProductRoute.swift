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

    public static func deepLinkResolve(
        pathComponents: [String],
        queryParameters: [String: String] = [:]
    ) -> AppRoute? {
        let host = pathComponents.first ?? ""
        guard host == deepLinkHost || host == "products" || host == "product-preload" || host == "products-preload" else {
            return nil
        }
        let subComponents = Array(pathComponents.dropFirst())

        // 1. Resolve ID from query param (?id=42 or ?productId=42)
        let idFromQuery: Int? = {
            if let idStr = queryParameters["id"] ?? queryParameters["product_id"] ?? queryParameters["productid"],
               let id = Int(idStr) {
                return id
            }
            return nil
        }()

        // 2. Resolve ID from path
        let idFromPath: Int? = {
            if subComponents.first == "preload" || subComponents.first == "detail" {
                if let next = subComponents.dropFirst().first, let id = Int(next) {
                    return id
                }
            } else if let first = subComponents.first, let id = Int(first) {
                return id
            }
            return nil
        }()

        // 3. Check preload via query param: ?preload=true or ?preload=42
        let idFromPreloadParam: Int? = {
            if let val = queryParameters["preload"], let id = Int(val) {
                return id
            }
            return nil
        }()

        let resolvedId = idFromQuery ?? idFromPreloadParam ?? idFromPath

        // 4. Check if preload flow is requested
        let isPreload = host.contains("preload")
            || subComponents.first == "preload"
            || queryParameters["preload"]?.lowercased() == "true"
            || idFromPreloadParam != nil

        if isPreload {
            if let resolvedId {
                return .deeplinkFetch(.product(id: resolvedId))
            }
            return .deeplinkFetch(.general)
        }

        if let resolvedId {
            return .product(.detailById(resolvedId))
        }

        return .product(.list)
    }
}
