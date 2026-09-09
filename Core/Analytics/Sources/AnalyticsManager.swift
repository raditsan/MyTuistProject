import Foundation

public protocol AnalyticsManagerProtocol: Sendable {
    var providers: [AnalyticsProviderProtocol] { get }

    func register(provider: AnalyticsProviderProtocol)
    func register(providers: [AnalyticsProviderProtocol])
    func removeProvider(named name: String)
    func getProvider(named name: String) -> AnalyticsProviderProtocol?

    func initialize()
    func logEvent(_ name: String, parameters: [String: Any]?)
    func logEvent(_ event: AnalyticsEvent)
    func logScreenView(screenName: String, screenClass: String?)
    func setUserId(_ userId: String?)
    func setUserProperty(name: String, value: String?)
    func reset()
}

// MARK: - Convenience Overload
extension AnalyticsManagerProtocol {
    public func logEvent(_ name: String) {
        logEvent(name, parameters: nil)
    }

    public func logScreenView(screenName: String) {
        logScreenView(screenName: screenName, screenClass: nil)
    }
}

// MARK: - Composite Analytics Manager Implementation
public final class AnalyticsManager: AnalyticsManagerProtocol, @unchecked Sendable {
    private var registeredProviders: [String: AnalyticsProviderProtocol] = [:]
    private let lock = NSRecursiveLock()

    public init(providers: [AnalyticsProviderProtocol] = []) {
        register(providers: providers)
    }

    public var providers: [AnalyticsProviderProtocol] {
        lock.lock()
        defer { lock.unlock() }
        return Array(registeredProviders.values)
    }

    public func register(provider: AnalyticsProviderProtocol) {
        lock.lock()
        defer { lock.unlock() }
        registeredProviders[provider.name] = provider
    }

    public func register(providers: [AnalyticsProviderProtocol]) {
        lock.lock()
        defer { lock.unlock() }
        for provider in providers {
            registeredProviders[provider.name] = provider
        }
    }

    public func removeProvider(named name: String) {
        lock.lock()
        defer { lock.unlock() }
        registeredProviders.removeValue(forKey: name)
    }

    public func getProvider(named name: String) -> AnalyticsProviderProtocol? {
        lock.lock()
        defer { lock.unlock() }
        return registeredProviders[name]
    }

    public func initialize() {
        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.initialize()
        }
    }

    public func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        let event = AnalyticsEvent(name: name, parameters: parameters)
        logEvent(event)
    }

    public func logEvent(_ event: AnalyticsEvent) {
        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.logEvent(event)
        }
    }

    public func logScreenView(screenName: String, screenClass: String? = nil) {
        let event = AnalyticsEvent.screenView(screenName: screenName, screenClass: screenClass)
        logEvent(event)
    }

    public func setUserId(_ userId: String?) {
        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.setUserId(userId)
        }
    }

    public func setUserProperty(name: String, value: String?) {
        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.setUserProperty(name: name, value: value)
        }
    }

    public func reset() {
        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.reset()
        }
    }
}
