import XCTest
@testable import CoreDesignSystem

final class StringExtTests: XCTestCase {

    func test_titleCase_emptyString() {
        XCTAssertEqual("".titleCase, "")
    }

    func test_titleCase_singleWordLowercase() {
        XCTAssertEqual("electronics".titleCase, "Electronics")
    }

    func test_titleCase_multipleWords() {
        XCTAssertEqual("hello world".titleCase, "Hello World")
    }

    func test_titleCase_uppercaseString() {
        XCTAssertEqual("MEN'S CLOTHING".titleCase, "Men's Clothing")
    }

    func test_titleCase_mixedCase() {
        XCTAssertEqual("sMaRt pHoNe".titleCase, "Smart Phone")
    }
}
