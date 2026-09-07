import SwiftUI
import CoreNavigation
import FeatureDeeplinkLoader

@MainActor
public struct DeeplinkRouteHandler {
    public static func buildView(for entryPoint: DeeplinkEntryPoint) -> AnyView {
        @ViewBuilder
        var view: some View {
            DeeplinkLoaderView(entryPoint: entryPoint)
        }
        return AnyView(view)
    }
}
