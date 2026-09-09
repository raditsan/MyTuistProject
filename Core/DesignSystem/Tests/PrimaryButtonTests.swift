import XCTest
import SwiftUI
@testable import CoreDesignSystem

final class PrimaryButtonTests: XCTestCase {
    func test_PrimaryButton_initialization() {
        var actionCalled = false
        let component = PrimaryButton(title: "Test Button") {
            actionCalled = true
        }
        XCTAssertEqual(component.title, "Test Button")
        component.action?()
        XCTAssertTrue(actionCalled)
    }

    func test_PrimaryButton_body_renders() {
        let component = PrimaryButton(title: "Test Button", action: {})
        _ = component.body
        let controller = UIHostingController(rootView: component)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}
