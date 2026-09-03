import Foundation

public struct DeepLinkHandler: Sendable {
    /// All registered route types that support deeplink resolution.
    private static let registeredRoutes: [any AppRouteType.Type] = [
        AppRoute.self,
        ProductRoute.self
    ]

    public init() {}

    /// Parses an incoming URL and resolves it to a matching AppRoute.
    public func parse(url: URL) -> AppRoute? {
        let host = url.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        let fullPath: [String]
        if let host, !pathComponents.contains(host) {
            fullPath = [host] + pathComponents
        } else {
            fullPath = pathComponents
        }

        for route in Self.registeredRoutes {
            if let resolved = route.deepLinkResolve(pathComponents: fullPath) {
                return resolved
            }
        }

        return nil
    }
}
