import SwiftUI
import CoreNavigation
import FeatureFavorites

@MainActor
public struct FavoritesRouteHandler {
    public static func buildView(for route: FavoritesRoute) -> AnyView {
        switch route {
        case .list:
            return AnyView(FavoritesView())
        }
    }
}
