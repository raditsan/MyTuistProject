import SwiftUI
import DomainProduct

// MARK: - Global App Route Enum
public enum AppRoute: AppRouteType {
    case splash
    case product(ProductRoute)

    public var destination: AppRouteDestination {
        switch self {
        case .splash:
            return .splash
        case .product(let route):
            return route.destination
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
        case "products", "product":
            if let idString = subComponents.first, let id = Int(idString) {
                return .product(.detailById(id))
            }
            return .product(.list)
        default:
            return nil
        }
    }
}
