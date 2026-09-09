import XCTest
import SwiftUI
import CoreLocalization
@testable import CoreDesignSystem

final class ErrorViewTests: XCTestCase {

    func test_ErrorView_initialization_defaults() {
        let sut = ErrorView(message: "An error occurred")
        XCTAssertEqual(sut.title, L10n.Common.Error.title)
        XCTAssertEqual(sut.message, "An error occurred")
        XCTAssertNil(sut.retryAction)
    }

    func test_ErrorView_initialization_customValues_andRetryAction() {
        var retryCalled = false
        let sut = ErrorView(
            title: "Custom Title",
            message: "Something went wrong",
            retryAction: {
                retryCalled = true
            }
        )

        XCTAssertEqual(sut.title, "Custom Title")
        XCTAssertEqual(sut.message, "Something went wrong")
        XCTAssertNotNil(sut.retryAction)

        sut.retryAction?()
        XCTAssertTrue(retryCalled)
    }

    func test_ErrorView_body_rendersWithoutRetryButton() {
        let sut = ErrorView(message: "No retry option")
        _ = sut.body
        let controller = UIHostingController(rootView: sut)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_ErrorView_body_rendersWithRetryButton() {
        let sut = ErrorView(
            title: "Error",
            message: "Tap to retry",
            retryAction: {}
        )
        _ = sut.body
        let controller = UIHostingController(rootView: sut)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}
