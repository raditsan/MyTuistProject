import XCTest
import SwiftUI
import CoreLocalization
@testable import CoreDesignSystem

final class LoadingViewTests: XCTestCase {

    func test_LoadingView_initialization_defaultMessage() {
        let sut = LoadingView()
        XCTAssertEqual(sut.message, L10n.Common.loading)
    }

    func test_LoadingView_initialization_customMessage() {
        let sut = LoadingView(message: "Mohon tunggu...")
        XCTAssertEqual(sut.message, "Mohon tunggu...")
    }

    func test_LoadingView_body_renders() {
        let sut = LoadingView(message: "Memuat...")
        _ = sut.body
        let controller = UIHostingController(rootView: sut)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}
