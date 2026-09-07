import SwiftUI
import CoreNavigation
import FeatureSplash

@MainActor
public struct SplashRouteHandler {
    public static func buildView() -> AnyView {
        @ViewBuilder
        var view: some View {
            SplashView()
        }
        return AnyView(view)
    }
}
