import SwiftUI
import CoreNavigation
import FeatureSplash

@MainActor
public struct SplashRouteHandler {
    public static func buildView() -> AnyView {
        AnyView(SplashView())
    }
}
