import SwiftUI
import CoreNavigation
import FeatureDeeplinkLoader

@MainActor
public struct DeeplinkRouteHandler {
    public static func buildView(for entryPoint: DeeplinkEntryPoint) -> AnyView {
        AnyView(DeeplinkLoaderView(entryPoint: entryPoint))
    }
}
