import Foundation
import UIKit

public protocol AnalyticsManagerProtocol: Sendable {
    var providers: [AnalyticsProviderProtocol] { get }
    var isAutomaticMetadataEnabled: Bool { get set }

    func register(provider: AnalyticsProviderProtocol)
    func register(providers: [AnalyticsProviderProtocol])
    func removeProvider(named name: String)
    func getProvider(named name: String) -> AnalyticsProviderProtocol?

    func setGlobalParameter(name: String, value: Any)
    func removeGlobalParameter(name: String)
    func clearGlobalParameters()

    func initialize()
    func logEvent(_ name: String, parameters: [String: Any]?)
    func logEvent(_ event: AnalyticsEvent)
    func logScreenView(screenName: String, screenClass: String?)
    func setUserId(_ userId: String?)
    func setUserProperty(name: String, value: String?)
    func recordError(_ error: Error, additionalParameters: [String: Any]?)
    func recordError(_ message: String, additionalParameters: [String: Any]?)
    func reset()
}

// MARK: - Convenience Overloads
extension AnalyticsManagerProtocol {
    public func logEvent(_ name: String) {
        logEvent(name, parameters: nil)
    }

    public func logScreenView(screenName: String) {
        logScreenView(screenName: screenName, screenClass: nil)
    }

    public func recordError(_ error: Error) {
        recordError(error, additionalParameters: nil)
    }

    public func recordError(_ message: String) {
        recordError(message, additionalParameters: nil)
    }
}

// MARK: - Simple Error Definition for Analytics
public struct SimpleAnalyticsError: LocalizedError, Sendable {
    public let message: String
    public var errorDescription: String? { message }

    public init(message: String) {
        self.message = message
    }
}

// MARK: - Composite Analytics Manager Implementation
public final class AnalyticsManager: AnalyticsManagerProtocol, @unchecked Sendable {
    private var registeredProviders: [String: AnalyticsProviderProtocol] = [:]
    private var globalParameters: [String: Any] = [:]
    private let lock = NSRecursiveLock()
    public var isAutomaticMetadataEnabled: Bool

    public init(
        providers: [AnalyticsProviderProtocol] = [],
        isAutomaticMetadataEnabled: Bool = true
    ) {
        self.isAutomaticMetadataEnabled = isAutomaticMetadataEnabled
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

    public func setGlobalParameter(name: String, value: Any) {
        lock.lock()
        defer { lock.unlock() }
        globalParameters[name] = value
    }

    public func removeGlobalParameter(name: String) {
        lock.lock()
        defer { lock.unlock() }
        globalParameters.removeValue(forKey: name)
    }

    public func clearGlobalParameters() {
        lock.lock()
        defer { lock.unlock() }
        globalParameters.removeAll()
    }

    private func getEnrichedParameters(from eventParams: [String: Any]?) -> [String: Any] {
        lock.lock()
        defer { lock.unlock() }

        var enriched: [String: Any] = [:]

        // 1. Automatic device & app metadata (if enabled)
        if isAutomaticMetadataEnabled {
            let bundle = Bundle.main
            let info = bundle.infoDictionary
            enriched["app_version"] = info?["CFBundleShortVersionString"] as? String ?? "1.0.0"
            enriched["build_number"] = info?["CFBundleVersion"] as? String ?? "1"
            enriched["environment"] = info?["ENVIRONMENT"] as? String ?? "Dev"
            enriched["platform"] = "iOS"
            enriched["os_version"] = UIDevice.current.systemVersion
            enriched["device_model"] = UIDevice.current.model
        }

        // 2. Custom global parameters
        for (key, val) in globalParameters {
            enriched[key] = val
        }

        // 3. Event-specific parameters (override global if key collision occurs)
        if let eventParams = eventParams {
            for (key, val) in eventParams {
                enriched[key] = val
            }
        }

        return enriched
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
        let enrichedParams = getEnrichedParameters(from: event.parameters)
        let enrichedEvent = AnalyticsEvent(name: event.name, parameters: enrichedParams)

        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.logEvent(enrichedEvent)
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

    public func recordError(_ error: Error, additionalParameters: [String: Any]? = nil) {
        let enrichedParams = getEnrichedParameters(from: additionalParameters)

        lock.lock()
        let activeProviders = Array(registeredProviders.values)
        lock.unlock()

        for provider in activeProviders where provider.isEnabled {
            provider.recordError(error, additionalParameters: enrichedParams)
        }
    }

    public func recordError(_ message: String, additionalParameters: [String: Any]? = nil) {
        let error = SimpleAnalyticsError(message: message)
        recordError(error, additionalParameters: additionalParameters)
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
