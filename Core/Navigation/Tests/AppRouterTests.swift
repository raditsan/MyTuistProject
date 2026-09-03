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
}
