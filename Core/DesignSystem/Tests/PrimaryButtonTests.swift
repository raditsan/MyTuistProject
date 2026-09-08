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
}
