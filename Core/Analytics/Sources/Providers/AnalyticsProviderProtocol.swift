import Foundation

public protocol AnalyticsProviderProtocol: AnyObject, Sendable {
    var name: String { get }
    var isEnabled: Bool { get set }

    func initialize()
    func logEvent(_ event: AnalyticsEvent)
    func setUserId(_ userId: String?)
    func setUserProperty(name: String, value: String?)
    func recordError(_ error: Error, additionalParameters: [String: Any]?)
    func reset()
}

// MARK: - Default Implementations
extension AnalyticsProviderProtocol {
    public func initialize() {}
    public func recordError(_ error: Error, additionalParameters: [String: Any]?) {}
    public func reset() {}
}
