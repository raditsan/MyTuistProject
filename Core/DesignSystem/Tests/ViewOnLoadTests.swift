import XCTest
import SwiftUI
@testable import CoreDesignSystem

final class ViewOnLoadTests: XCTestCase {

    func test_onLoad_syncModifier_canBeApplied() {
        var callCount = 0
        let view = Text("Hello").onLoad {
            callCount += 1
        }
        XCTAssertNotNil(view)
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_onLoad_asyncModifier_canBeApplied() {
        let view = Text("Hello").onLoad {
            try? await _Concurrency.Task.sleep(nanoseconds: 1_000)
        }
        XCTAssertNotNil(view)
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_viewDidLoadModifier_actionCallback() {
        var callCount = 0
        let modifier = ViewDidLoadModifier {
            callCount += 1
        }
        modifier.action()
        XCTAssertEqual(callCount, 1)
    }
}
