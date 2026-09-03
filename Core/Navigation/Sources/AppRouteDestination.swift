import SwiftUI
import UIKit

// MARK: - App Route Destination
/// Parameterless enum representing all target destinations in the navigation stack.
/// Used for clean pop back matching without associated values.
public enum AppRouteDestination: Hashable, Sendable {
    case splash
    case productList
    case productDetail
    case product(ProductDestination)
}

// MARK: - Feature Destination Protocol
public protocol FeatureDestination: CaseIterable, Sendable, Hashable {}

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
    static func deepLinkResolve(pathComponents: [String]) -> AppRoute?
}

public extension AppRouteType {
    var sheetConfiguration: SheetConfiguration? { nil }
    static var deepLinkHost: String? { nil }
    static func deepLinkResolve(pathComponents: [String]) -> AppRoute? { nil }
}

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
