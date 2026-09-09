import XCTest
import SwiftUI
@testable import CoreDesignSystem

final class ViewOnLoadTests: XCTestCase {

    func test_onLoad_modifierCanBeApplied() {
        var callCount = 0
        let view = Text("Hello")
            .onLoad {
                callCount += 1
            }

        XCTAssertNotNil(view)
    }

    func test_onLoad_asyncModifierCanBeApplied() {
        let view = Text("Hello")
            .onLoad {
                try? await _Concurrency.Task.sleep(nanoseconds: 1_000)
            }

        XCTAssertNotNil(view)
    }
}
