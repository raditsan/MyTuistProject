import SwiftUI
import DomainProduct

// MARK: - Global App Route Enum
public enum AppRoute: AppRouteType {
    case splash
    case deeplinkFetch(DeeplinkEntryPoint)
    case product(ProductRoute)
    case favorites(FavoritesRoute)

    public var destination: AppRouteDestination {
        switch self {
        case .splash:
            return .splash
        case .deeplinkFetch:
            return .deeplinkFetch
        case .product(let route):
            return route.destination
        case .favorites(let route):
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

    public static func deepLinkResolve(
        pathComponents: [String],
        queryParameters: [String: String] = [:]
    ) -> AppRoute? {
        let host = pathComponents.first ?? ""

        switch host {
        case "splash":
            return .splash

        default:
            return nil
        }
    }
}
