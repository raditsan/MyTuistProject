import XCTest
import SwiftUI
@testable import CoreDesignSystem

final class AsyncRemoteImageTests: XCTestCase {

    func test_AsyncRemoteImage_initialization_defaultContentMode() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/test.png")
        XCTAssertEqual(sut.urlString, "https://example.com/test.png")
        XCTAssertEqual(sut.contentMode, .fit)
    }

    func test_AsyncRemoteImage_initialization_customContentMode() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/banner.png", contentMode: .fill)
        XCTAssertEqual(sut.urlString, "https://example.com/banner.png")
        XCTAssertEqual(sut.contentMode, .fill)
    }

    func test_AsyncRemoteImage_body_rendersHostingController() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/test.png")
        _ = sut.body
        let controller = UIHostingController(rootView: sut)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_AsyncRemoteImage_phaseEmpty_renders() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/test.png")
        let view = sut.contentView(for: .empty)
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_AsyncRemoteImage_phaseSuccess_renders() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/test.png", contentMode: .fill)
        let dummyImage = Image(systemName: "star")
        let view = sut.contentView(for: .success(dummyImage))
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }

    func test_AsyncRemoteImage_phaseFailure_renders() {
        let sut = AsyncRemoteImage(urlString: "https://example.com/test.png")
        let error = URLError(.badURL)
        let view = sut.contentView(for: .failure(error))
        let controller = UIHostingController(rootView: view)
        controller.loadViewIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}
