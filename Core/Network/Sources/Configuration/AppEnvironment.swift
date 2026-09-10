import Foundation

public enum AppEnvironment: String, Sendable, CaseIterable {
    case dev
    case uat
    case prod

    /// Optional environment override for testing purposes.
    public static var environmentOverride: AppEnvironment?

    public static func resolve(
        infoDictionary: [String: Any]? = Bundle.main.infoDictionary,
        bundleIdentifier: String? = Bundle.main.bundleIdentifier
    ) -> AppEnvironment {
        // 1. Check Info.plist ENVIRONMENT key
        if let envString = infoDictionary?["ENVIRONMENT"] as? String,
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }

        // 2. Fallback to Bundle Identifier suffix
        let bundleId = bundleIdentifier ?? ""
        if bundleId.hasSuffix(".dev") {
            return .dev
        } else if bundleId.hasSuffix(".uat") {
            return .uat
        }

        return .prod
    }

    public static var current: AppEnvironment {
        if let override = environmentOverride {
            return override
        }
        return resolve()
    }

    public static func resolveBaseURL(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> String {
        if let url = infoDictionary?["BASE_URL"] as? String,
           !url.isEmpty, !url.contains("$()") {
            return url
        }
        return "https://fakestoreapi.com"
    }

    public static var baseURL: String {
        resolveBaseURL()
    }

    public static func resolveAppName(infoDictionary: [String: Any]? = Bundle.main.infoDictionary) -> String {
        if let name = infoDictionary?["CFBundleDisplayName"] as? String,
           !name.isEmpty {
            return name
        }
        return (infoDictionary?["CFBundleName"] as? String) ?? "MyTuist"
    }

    public static var appName: String {
        resolveAppName()
    }

    public static var isProduction: Bool {
        current == .prod
    }

    public static var isDevelopment: Bool {
        current == .dev
    }

    public static var isUAT: Bool {
        current == .uat
    }
}
