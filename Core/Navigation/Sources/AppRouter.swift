import SwiftUI
import UIKit
import Combine

// MARK: - AppRouter

/// Responsible for navigation mechanics (push, pop, present, dismiss, deep link).
/// Conforms to generic AppRouteType and handles dynamic view resolution.
@MainActor
public final class AppRouter: ObservableObject {
    public typealias RouteViewBuilder = @MainActor (AppRoute) -> AnyView
    public static var viewBuilder: RouteViewBuilder = { _ in AnyView(EmptyView()) }

    public let navigationController: UINavigationController
    public let alertCoordinator = AlertCoordinator()

    public init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController ?? UINavigationController()
    }

    // MARK: - Toasts & Alerts

    public func showToast(_ toast: ToastMessage) {
        alertCoordinator.showToast(toast)
    }

    public func showToast(title: String, message: String? = nil, style: ToastMessage.ToastStyle = .info) {
        alertCoordinator.showToast(ToastMessage(title: title, message: message, style: style))
    }

    // MARK: - Root

    public func setRootView<V: View>(_ view: V) {
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: nil)
        navigationController.setViewControllers([hosting], animated: false)
    }

    /// Sets the root view from any generic route conforming to AppRouteType.
    public func setRootView<R: AppRouteType>(to route: R) {
        let view = route.makeView()
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: route.destination)
        navigationController.setViewControllers([hosting], animated: false)
    }

    /// Sets the root view from a global AppRoute (supports leading dot syntax: router.setRootView(to: .splash)).
    public func setRootView(to route: AppRoute) {
        let view = route.makeView()
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: route.destination)
        navigationController.setViewControllers([hosting], animated: false)
    }

    // MARK: - Deep Link Engine

    /// Handles an incoming deep link URL and navigates to the resolved route.
    public func handle(url: URL) {
        let host = url.host?.lowercased()
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        let fullPath: [String]
        if let host, !pathComponents.contains(host) {
            fullPath = [host] + pathComponents
        } else {
            fullPath = pathComponents
        }

        if let resolvedRoute = AppRoute.deepLinkResolve(pathComponents: fullPath) {
            if case let .deeplinkFetch(entryPoint) = resolvedRoute {
                deeplinkLoader(entryPoint)
            } else {
                navigate(to: resolvedRoute)
            }
        }
    }

    // MARK: - Navigation Engine

    /// Direct call syntax: router.navigate(.product(.detail(product)))
    public func navigate(_ route: AppRoute, animated: Bool = true) {
        navigate(to: route, animated: animated)
    }

    /// Explicit parameter syntax: router.navigate(to: .product(.detail(product)))
    public func navigate(to route: AppRoute, animated: Bool = true) {
        let view = route.makeView()
        push(view, destination: route.destination, animated: animated)
    }

    /// Navigates to any generic route conforming to AppRouteType.
    public func navigate<R: AppRouteType>(to route: R, animated: Bool = true) {
        let view = route.makeView()
        push(view, destination: route.destination, animated: animated)
    }

    /// Direct call syntax for any generic route conforming to AppRouteType.
    public func navigate<R: AppRouteType>(_ route: R, animated: Bool = true) {
        navigate(to: route, animated: animated)
    }

    public func push<V: View>(_ view: V, destination: AppRouteDestination? = nil, animated: Bool = true) {
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: destination)
        navigationController.pushViewController(hosting, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    public func popToRoute(_ destination: AppRouteDestination, animated: Bool = true) {
        let targetVC = navigationController.viewControllers.last { vc in
            guard let identifiable = vc as? RouteIdentifiable else { return false }
            return identifiable.routeDestination == destination
        }

        if let target = targetVC {
            navigationController.popToViewController(target, animated: animated)
        }
    }
    
    public func dismissDeeplinkLoader() async {
        await withCheckedContinuation { continuation in
            navigationController.dismiss(animated: false) {
                continuation.resume()
            }
        }
    }
    
    public func deeplinkLoader(_ entrypoint: DeeplinkEntryPoint) {
        let route: AppRoute = .deeplinkFetch(entrypoint)
        let view = route.makeView()
        present(
            view,
            style: .overFullScreen,
            configuration: SheetConfiguration(isTransparent: true),
            animated: false
        )
    }

    // MARK: - Modal Presentations

    public func presentSheet<V: View>(
        _ view: V,
        configuration: SheetConfiguration = .default,
        animated: Bool = true
    ) {
        present(view, style: .pageSheet, configuration: configuration, animated: animated)
    }

    public func presentSheet(
        to route: AppRoute,
        configuration: SheetConfiguration? = nil,
        animated: Bool = true
    ) {
        let view = route.makeView()
        let effectiveConfig = configuration ?? route.sheetConfiguration ?? .default
        present(view, style: .pageSheet, configuration: effectiveConfig, animated: animated)
    }

    public func presentSheet<R: AppRouteType>(
        to route: R,
        configuration: SheetConfiguration? = nil,
        animated: Bool = true
    ) {
        let view = route.makeView()
        let effectiveConfig = configuration ?? route.sheetConfiguration ?? .default
        present(view, style: .pageSheet, configuration: effectiveConfig, animated: animated)
    }

    public func dismissModal(animated: Bool = true, completion: (() -> Void)? = nil) {
        navigationController.dismiss(animated: animated, completion: completion)
    }

    public func dismissModalAsync(animated: Bool = true) async {
        await withCheckedContinuation { continuation in
            navigationController.dismiss(animated: animated) {
                continuation.resume()
            }
        }
    }

    // MARK: - Private Generic Helpers

    private func present<V: View>(
        _ view: V,
        style: UIModalPresentationStyle = .automatic,
        configuration: SheetConfiguration = .default,
        animated: Bool = true
    ) {
        let hosting = UIHostingController(rootView: addEnvironment(to: view))
        hosting.modalPresentationStyle = style

        if configuration.isTransparent {
            hosting.view.backgroundColor = .clear
            hosting.view.isOpaque = false
        }

        if #available(iOS 15.0, *), let sheet = hosting.sheetPresentationController {
            let uikitDetents: [UISheetPresentationController.Detent] = configuration.detents.map { $0.uiKitDetent }
            sheet.detents = uikitDetents.isEmpty ? [.large()] : uikitDetents

            let initialDetent = configuration.selectedDetent ?? configuration.detents.first
            if let selectedIdentifier = initialDetent?.uiKitIdentifier {
                sheet.selectedDetentIdentifier = selectedIdentifier
            }

            switch configuration.dragIndicator {
            case .visible:
                sheet.prefersGrabberVisible = true
            case .hidden:
                sheet.prefersGrabberVisible = false
            case .automatic:
                sheet.prefersGrabberVisible = configuration.detents.count > 1
            }

            if let cornerRadius = configuration.cornerRadius {
                sheet.preferredCornerRadius = cornerRadius
            }

            if let undimmed = configuration.largestUndimmedDetent?.uiKitIdentifier {
                sheet.largestUndimmedDetentIdentifier = undimmed
            }

            sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        }

        navigationController.present(hosting, animated: animated)
    }

    public func addEnvironment<V: View>(to content: V) -> some View {
        content
            .environmentObject(self)
            .environmentObject(alertCoordinator)
    }
}

// MARK: - NavigationControllerContainer

public struct NavigationControllerContainer: UIViewControllerRepresentable {
    let navigationController: UINavigationController

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func makeUIViewController(context: Context) -> UINavigationController {
        return navigationController
    }

    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - LazyView

public struct LazyView<Content: View>: View {
    private let build: () -> Content

    public init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }

    public var body: some View {
        build()
    }
}
