import Foundation

public struct DeepLinkHandler: Sendable {
    /// All registered route types that support deeplink resolution.
    public private(set) static var registeredRoutes: [any AppRouteType.Type] = [
        ProductRoute.self,
        FavoritesRoute.self,
        AppRoute.self
    ]

    public init() {}

    /// Registers an additional route type for deeplink resolution.
    public static func register(_ routeType: any AppRouteType.Type) {
        registeredRoutes.append(routeType)
    }

    /// Parses an incoming URL and resolves it to a matching AppRoute.
    public func parse(url: URL) -> AppRoute? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = components?.host?.lowercased() ?? url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        let fullPath: [String]
        if !host.isEmpty && !pathComponents.contains(host) {
            fullPath = [host] + pathComponents
        } else {
            fullPath = pathComponents
        }

        var queryParameters: [String: String] = [:]
        for item in components?.queryItems ?? [] {
            queryParameters[item.name.lowercased()] = item.value
            queryParameters[item.name] = item.value
        }

        for route in Self.registeredRoutes {
            if let resolved = route.deepLinkResolve(pathComponents: fullPath, queryParameters: queryParameters) {
                return resolved
            }
        }

        return nil
    }
}
