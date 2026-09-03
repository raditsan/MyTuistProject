import Foundation
import CoreNavigation
import FeatureProduct

public struct DeepLinkHandler: Sendable {
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

        return AppRoute.deepLinkResolve(pathComponents: fullPath)
    }
}
