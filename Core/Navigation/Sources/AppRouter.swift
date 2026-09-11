import SwiftUI
import UIKit
import Combine
import FactoryKit
import CoreLocalization

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

    // MARK: - Splash & State Engine

    /// Holds any incoming deep link that arrives while the splash screen is active.
    /// This route will be automatically executed as soon as the splash screen finishes loading.
    public private(set) var pendingDeepLinkRoute: AppRoute?

    /// Indicates whether the app is currently in the splash phase.
    public var isSplashActive: Bool {
        (navigationController.viewControllers.first as? RouteIdentifiable)?.routeDestination == .splash
    }

    /// Completes the splash screen phase, transitions to the base root, and executes any pending deep link.
    public func completeSplash() {
        guard let pending = pendingDeepLinkRoute else {
            return
        }
        navigateDeeplink(to: pending)
    }

    /// Clears any pending deep link route without navigating.
    public func clearPendingDeepLink() {
        pendingDeepLinkRoute = nil
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

    private let deepLinkHandler = DeepLinkHandler()

    /// Handles an incoming deep link URL and navigates to the resolved route.
    /// If currently on the splash screen, queues the deep link so that splash screen can finish
    /// loading configs/APIs before navigating to the target screen.
    public func handle(url: URL) {
        guard let resolvedRoute = deepLinkHandler.parse(url: url) else { return }

        if isSplashActive {
            // Splash masih aktif (sedang loading config/API) -> simpan ke pending queue
            pendingDeepLinkRoute = resolvedRoute
        } else {
            navigateDeeplink(to: resolvedRoute)
        }
    }
    
    private func navigateDeeplink(to route: AppRoute) {
        if case let .deeplinkFetch(entryPoint) = route {
            deeplinkLoader(entryPoint)
        } else {
            navigate(to: route, animated: false)
        }
        clearPendingDeepLink()
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
        guard navigationController.presentedViewController != nil else { return }
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
        guard navigationController.presentedViewController != nil else { return }
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
            .modifier(LocalizationObserverModifier())
            .environmentObject(self)
            .environmentObject(alertCoordinator)
    }
}

// MARK: - Localization Observer
private struct LocalizationObserverModifier: ViewModifier {
    @InjectedObject(\.localizationManager) private var localizationManager: LocalizationManager

    func body(content: Content) -> some View {
        content
            .environmentObject(localizationManager)
            .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
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
