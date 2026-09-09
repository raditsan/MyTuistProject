import Foundation

public final class ConsoleAnalyticsProvider: AnalyticsProviderProtocol, @unchecked Sendable {
    public let name: String = "Console"
    public var isEnabled: Bool

    public init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    public func initialize() {
        guard isEnabled else { return }
        print("[Analytics - Console] 🚀 Initialized")
    }

    public func logEvent(_ event: AnalyticsEvent) {
        guard isEnabled else { return }
        if let params = event.parameters, !params.isEmpty {
            print("[Analytics - Console] 📊 Event: '\(event.name)', Parameters: \(params)")
        } else {
            print("[Analytics - Console] 📊 Event: '\(event.name)'")
        }
    }

    public func setUserId(_ userId: String?) {
        guard isEnabled else { return }
        print("[Analytics - Console] 👤 Set User ID: '\(userId ?? "nil")'")
    }

    public func setUserProperty(name: String, value: String?) {
        guard isEnabled else { return }
        print("[Analytics - Console] 🏷️ Set User Property: '\(name)' = '\(value ?? "nil")'")
    }

    public func recordError(_ error: Error, additionalParameters: [String: Any]? = nil) {
        guard isEnabled else { return }
        if let params = additionalParameters, !params.isEmpty {
            print("[Analytics - Console] ❌ Error: '\(error.localizedDescription)', Parameters: \(params)")
        } else {
            print("[Analytics - Console] ❌ Error: '\(error.localizedDescription)'")
        }
    }

    public func reset() {
        guard isEnabled else { return }
        print("[Analytics - Console] 🔄 Reset Session")
    }
}
