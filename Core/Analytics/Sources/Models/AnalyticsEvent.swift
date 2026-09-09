import Foundation

public struct AnalyticsEvent: @unchecked Sendable {
    public let name: String
    public let parameters: [String: Any]?

    public init(name: String, parameters: [String: Any]? = nil) {
        self.name = name
        self.parameters = parameters
    }
}

// MARK: - Standard Events Helper
extension AnalyticsEvent {
    public static func screenView(screenName: String, screenClass: String? = nil) -> AnalyticsEvent {
        var params: [String: Any] = ["screen_name": screenName]
        if let screenClass = screenClass {
            params["screen_class"] = screenClass
        }
        return AnalyticsEvent(name: "screen_view", parameters: params)
    }

    public static func buttonClick(buttonName: String, screenName: String? = nil) -> AnalyticsEvent {
        var params: [String: Any] = ["button_name": buttonName]
        if let screenName = screenName {
            params["screen_name"] = screenName
        }
        return AnalyticsEvent(name: "button_click", parameters: params)
    }
}
