import SwiftUI
import CoreNavigation
import FeatureFavorites

@MainActor
public struct FavoritesRouteHandler {
    public static func buildView(for route: FavoritesRoute) -> AnyView {
        @ViewBuilder
        var view: some View {
            switch route {
            case .list:
                FavoritesView()
            }
        }
        return AnyView(view)
    }
}
