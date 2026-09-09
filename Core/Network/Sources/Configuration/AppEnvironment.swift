import Foundation

public enum AppEnvironment: String, Sendable, CaseIterable {
    case dev
    case uat
    case prod

    public static var current: AppEnvironment {
        // 1. Check Info.plist ENVIRONMENT key
        if let envString = Bundle.main.object(forInfoDictionaryKey: "ENVIRONMENT") as? String,
           let env = AppEnvironment(rawValue: envString.lowercased()) {
            return env
        }

        // 2. Fallback to Bundle Identifier suffix
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        if bundleId.hasSuffix(".dev") {
            return .dev
        } else if bundleId.hasSuffix(".uat") {
            return .uat
        }

        return .prod
    }

    public static var baseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "BASE_URL") as? String,
           !url.isEmpty, !url.contains("$()") {
            return url
        }
        return "https://fakestoreapi.com"
    }

    public static var appName: String {
        if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String,
           !name.isEmpty {
            return name
        }
        return (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "MyTuist"
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
