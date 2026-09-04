import SwiftUI

public enum FavoritesRoute: AppRouteType {
    case list

    public var destination: AppRouteDestination {
        switch self {
        case .list:
            return .favorites(.list)
        }
    }

    @MainActor @ViewBuilder
    public func makeView() -> some View {
        AppRouter.viewBuilder(.favorites(self))
    }

    public static var deepLinkHost: String? { "favorites" }

    public static func deepLinkResolve(pathComponents: [String]) -> AppRoute? {
        guard pathComponents.first == deepLinkHost || pathComponents.first == "favorite" else { return nil }
        return .favorites(.list)
    }
}
