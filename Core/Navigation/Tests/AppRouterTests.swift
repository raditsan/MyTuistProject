import XCTest
import SwiftUI
@testable import CoreNavigation

private struct DummyScreen: View {
    var body: some View {
        Text("Dummy Screen")
    }
}

private enum DummyRoute: AppRouteType {
    case first
    case second

    var destination: AppRouteDestination {
        switch self {
        case .first: return .productList
        case .second: return .productDetail
        }
    }

    @MainActor @ViewBuilder
    func makeView() -> some View {
        DummyScreen()
    }
}

@MainActor
final class AppRouterTests: XCTestCase {
    private var sut: AppRouter!

    override func setUp() {
        super.setUp()
        sut = AppRouter(navigationController: UINavigationController())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_setRootView_setsNavigationStack() {
        // When
        sut.setRootView(to: DummyRoute.first)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
        let rootVC = sut.navigationController.viewControllers.first as? RouteIdentifiable
        XCTAssertEqual(rootVC?.routeDestination, .productList)
    }

    func test_navigate_pushesViewController() {
        // Given
        sut.setRootView(to: DummyRoute.first)

        // When
        sut.navigate(to: DummyRoute.second, animated: false)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .productDetail)
    }

    func test_pop_removesTopViewController() {
        // Given
        sut.setRootView(to: DummyRoute.first)
        sut.navigate(to: DummyRoute.second, animated: false)
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)

        // When
        sut.pop(animated: false)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 1)
    }

    func test_showToast_updatesCurrentToast() {
        // Given
        let toast = ToastMessage(title: "Berhasil", message: "Item ditambahkan", style: .success)

        // When
        sut.showToast(toast)

        // Then
        XCTAssertEqual(sut.alertCoordinator.currentToast?.title, "Berhasil")
        XCTAssertEqual(sut.alertCoordinator.currentToast?.style, .success)
    }

    func test_deepLinkResolve_resolvesProductListAndDetail() {
        // When: URL "mytuist://product"
        let url1 = URL(string: "mytuist://product")!
        let pathComponents1 = [url1.host!].compactMap { $0 } + url1.pathComponents.filter { $0 != "/" }
        let resolvedRoute1 = AppRoute.deepLinkResolve(pathComponents: pathComponents1)

        // Then
        XCTAssertEqual(resolvedRoute1, .product(.list))

        // When: URL "mytuist://product/42"
        let url2 = URL(string: "mytuist://product/42")!
        let pathComponents2 = [url2.host!].compactMap { $0 } + url2.pathComponents.filter { $0 != "/" }
        let resolvedRoute2 = AppRoute.deepLinkResolve(pathComponents: pathComponents2)

        // Then
        XCTAssertEqual(resolvedRoute2, .product(.detailById(42)))
    }

    func test_handleURL_navigatesToResolvedRoute() {
        // Given
        AppRouter.viewBuilder = { route in
            AnyView(Text("Mock View for \(String(describing: route))"))
        }
        sut.setRootView(to: .splash)

        // When
        let url = URL(string: "mytuist://product/99")!
        sut.handle(url: url)

        // Then
        XCTAssertEqual(sut.navigationController.viewControllers.count, 2)
        let topVC = sut.navigationController.viewControllers.last as? RouteIdentifiable
        XCTAssertEqual(topVC?.routeDestination, .product(.detail))
    }
}
