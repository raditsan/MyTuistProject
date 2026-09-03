import SwiftUI
import UIKit

// MARK: - App Route Destination
/// Parameterless enum representing all target destinations in the navigation stack.
/// Used for clean pop back matching without associated values.
public enum AppRouteDestination: Hashable, Sendable {
    case productList
    case productDetail
    case custom(String)
}

// MARK: - Route Identifiable Protocol & Class
public protocol RouteIdentifiable {
    var routeDestination: AppRouteDestination? { get }
}

// MARK: - AppRouteType Protocol
public protocol AppRouteType: Hashable {
    associatedtype RouteView: View
    var destination: AppRouteDestination { get }
    @MainActor @ViewBuilder func makeView() -> RouteView
    var sheetConfiguration: SheetConfiguration? { get }
    static var deepLinkHost: String? { get }
    static func deepLinkResolve(pathComponents: [String]) -> (any AppRouteType)?
}

public extension AppRouteType {
    var sheetConfiguration: SheetConfiguration? { nil }
    static var deepLinkHost: String? { nil }
    static func deepLinkResolve(pathComponents: [String]) -> (any AppRouteType)? { nil }
}

// MARK: - AnyAppRoute
public struct AnyAppRoute: Hashable {
    public let destination: AppRouteDestination
    public let sheetConfiguration: SheetConfiguration?
    private let _makeView: @MainActor () -> AnyView
    private let _equals: (AnyAppRoute) -> Bool
    private let _hash: (inout Hasher) -> Void

    public init<R: AppRouteType>(_ route: R) {
        self.destination = route.destination
        self.sheetConfiguration = route.sheetConfiguration
        self._makeView = { AnyView(route.makeView()) }
        self._equals = { other in
            guard let otherRoute = other as? R else { return false }
            return route == otherRoute
        }
        self._hash = { hasher in
            route.hash(into: &hasher)
        }
    }

    public static func == (lhs: AnyAppRoute, rhs: AnyAppRoute) -> Bool {
        lhs.destination == rhs.destination
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(destination)
    }

    @MainActor
    public func makeView() -> AnyView {
        _makeView()
    }
}

// MARK: - RouteHostingController
public final class RouteHostingController<Content: View>: UIHostingController<Content>, RouteIdentifiable {
    public let routeDestination: AppRouteDestination?

    public init(rootView: Content, routeDestination: AppRouteDestination?) {
        self.routeDestination = routeDestination
        super.init(rootView: rootView)
    }

    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
