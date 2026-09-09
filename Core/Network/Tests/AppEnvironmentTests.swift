import XCTest
@testable import CoreNetwork

final class AppEnvironmentTests: XCTestCase {
    func test_currentEnvironment_hasValidValue() {
        let env = AppEnvironment.current
        XCTAssertTrue(AppEnvironment.allCases.contains(env))
    }

    func test_baseURL_hasDefaultValue() {
        let url = AppEnvironment.baseURL
        XCTAssertFalse(url.isEmpty)
        XCTAssertTrue(url.hasPrefix("http"))
    }

    func test_appName_hasDefaultValue() {
        let name = AppEnvironment.appName
        XCTAssertFalse(name.isEmpty)
    }

    func test_environmentFlags() {
        let env = AppEnvironment.current
        switch env {
        case .dev:
            XCTAssertTrue(AppEnvironment.isDevelopment)
            XCTAssertFalse(AppEnvironment.isProduction)
        case .uat:
            XCTAssertTrue(AppEnvironment.isUAT)
            XCTAssertFalse(AppEnvironment.isProduction)
        case .prod:
            XCTAssertTrue(AppEnvironment.isProduction)
            XCTAssertFalse(AppEnvironment.isDevelopment)
        }
    }
}
