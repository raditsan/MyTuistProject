import SwiftUI
import UIKit
import Combine
import DomainProduct

// MARK: - AppRouter

/// Responsible ONLY for navigation mechanics (push, pop, present, dismiss).
/// View construction and route mapping are encapsulated within each route.
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

    /// Sets the root view from any route conforming to AppRouteType.
    public func setRootView<R: AppRouteType>(to route: R) {
        let view = route.makeView()
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: route.destination)
        navigationController.setViewControllers([hosting], animated: false)
    }

    /// Sets the root view from a global AppRoute (e.g. router.setRootView(to: .productList)).
    public func setRootView(to route: AppRoute) {
        let view = route.makeView()
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: route.destination)
        navigationController.setViewControllers([hosting], animated: false)
    }

    // MARK: - Deep Link Engine

    /// Handles an incoming deep link URL and navigates to the resolved route.
    public func handle(url: URL) {
        let deepLinkHandler = DeepLinkHandler()
        if let targetRoute = deepLinkHandler.parse(url: url) {
            navigate(to: targetRoute)
        }
    }

    // MARK: - Navigation Engine

    /// Direct call syntax: `router.navigate(.productDetail(product))`
    public func navigate(_ route: AppRoute, animated: Bool = true) {
        navigate(to: route, animated: animated)
    }

    /// Explicit parameter syntax: `router.navigate(to: .productDetail(product))`
    public func navigate(to route: AppRoute, animated: Bool = true) {
        let view = route.makeView()
        push(view, destination: route.destination, animated: animated)
    }

    /// Navigates to any route conforming to AppRouteType.
    public func navigate<R: AppRouteType>(to route: R, animated: Bool = true) {
        let view = route.makeView()
        push(view, destination: route.destination, animated: animated)
    }

    /// Pushes any concrete View onto the navigation stack, wrapping it in a RouteHostingController.
    private func push<V: View>(_ view: V, destination: AppRouteDestination? = nil, animated: Bool = true) {
        let hosting = RouteHostingController(rootView: addEnvironment(to: view), routeDestination: destination)
        navigationController.pushViewController(hosting, animated: animated)
    }

    public func pop(animated: Bool = true) {
        navigationController.popViewController(animated: animated)
    }

    /// Pops back to a specific route destination on the navigation stack.
    public func popToRoute(_ destination: AppRouteDestination, animated: Bool = true) {
        let targetVC = navigationController.viewControllers.last { vc in
            guard let identifiable = vc as? RouteIdentifiable else { return false }
            return identifiable.routeDestination == destination
        }

        if let target = targetVC {
            navigationController.popToViewController(target, animated: animated)
        }
    }

    // MARK: - Modal Presentations

    /// Presents any concrete View as a modal sheet with configurable configuration.
    public func presentSheet<V: View>(
        _ view: V,
        configuration: SheetConfiguration = .default,
        animated: Bool = true
    ) {
        present(view, style: .pageSheet, configuration: configuration, animated: animated)
    }

    /// Presents any route conforming to AppRouteType as a modal sheet.
    public func presentSheet<R: AppRouteType>(
        to route: R,
        configuration: SheetConfiguration? = nil,
        animated: Bool = true
    ) {
        let view = route.makeView()
        let effectiveConfig = configuration ?? route.sheetConfiguration ?? .default
        present(view, style: .pageSheet, configuration: effectiveConfig, animated: animated)
    }

    /// Presents a global AppRoute as a modal sheet.
    public func presentSheet(
        to route: AppRoute,
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

    /// Injects shared environment values into any View.
    private func addEnvironment<V: View>(to content: V) -> some View {
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
