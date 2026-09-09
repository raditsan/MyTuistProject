import SwiftUI
import FactoryKit

public struct ScreenTrackingModifier: ViewModifier {
    public let screenName: String
    public let screenClass: String?
    public let parameters: [String: Any]?
    @Injected(\.analytics) private var analytics

    public init(
        screenName: String,
        screenClass: String? = nil,
        parameters: [String: Any]? = nil
    ) {
        self.screenName = screenName
        self.screenClass = screenClass
        self.parameters = parameters
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                analytics.logScreenView(screenName: screenName, screenClass: screenClass)
                if let parameters = parameters, !parameters.isEmpty {
                    analytics.logEvent("screen_appear_\(screenName)", parameters: parameters)
                }
            }
    }
}

// MARK: - View Extension
extension View {
    public func trackScreen(
        _ screenName: String,
        screenClass: String? = nil,
        parameters: [String: Any]? = nil
    ) -> some View {
        modifier(ScreenTrackingModifier(
            screenName: screenName,
            screenClass: screenClass,
            parameters: parameters
        ))
    }
}
