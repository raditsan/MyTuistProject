import XCTest
@testable import CoreNetwork

final class AppEnvironmentTests: XCTestCase {

    override func tearDown() {
        AppEnvironment.environmentOverride = nil
        super.tearDown()
    }

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

    func test_environmentFlags_withOverrides() {
        AppEnvironment.environmentOverride = .dev
        XCTAssertTrue(AppEnvironment.isDevelopment)
        XCTAssertFalse(AppEnvironment.isProduction)
        XCTAssertFalse(AppEnvironment.isUAT)
        XCTAssertEqual(AppEnvironment.current, .dev)

        AppEnvironment.environmentOverride = .uat
        XCTAssertTrue(AppEnvironment.isUAT)
        XCTAssertFalse(AppEnvironment.isProduction)
        XCTAssertFalse(AppEnvironment.isDevelopment)
        XCTAssertEqual(AppEnvironment.current, .uat)

        AppEnvironment.environmentOverride = .prod
        XCTAssertTrue(AppEnvironment.isProduction)
        XCTAssertFalse(AppEnvironment.isDevelopment)
        XCTAssertFalse(AppEnvironment.isUAT)
        XCTAssertEqual(AppEnvironment.current, .prod)
    }

    func test_resolve_fromInfoPlist() {
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: ["ENVIRONMENT": "dev"]), .dev)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: ["ENVIRONMENT": "DEV"]), .dev)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: ["ENVIRONMENT": "uat"]), .uat)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: ["ENVIRONMENT": "prod"]), .prod)
    }

    func test_resolve_fromBundleIdentifierSuffix() {
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: nil, bundleIdentifier: "com.app.dev"), .dev)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: nil, bundleIdentifier: "com.app.uat"), .uat)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: nil, bundleIdentifier: "com.app.release"), .prod)
        XCTAssertEqual(AppEnvironment.resolve(infoDictionary: nil, bundleIdentifier: nil), .prod)
    }

    func test_resolveBaseURL() {
        XCTAssertEqual(AppEnvironment.resolveBaseURL(infoDictionary: ["BASE_URL": "https://api.mycustom.com"]), "https://api.mycustom.com")
        XCTAssertEqual(AppEnvironment.resolveBaseURL(infoDictionary: ["BASE_URL": "$()"]), "https://fakestoreapi.com")
        XCTAssertEqual(AppEnvironment.resolveBaseURL(infoDictionary: ["BASE_URL": ""]), "https://fakestoreapi.com")
        XCTAssertEqual(AppEnvironment.resolveBaseURL(infoDictionary: nil), "https://fakestoreapi.com")
    }

    func test_resolveAppName() {
        XCTAssertEqual(AppEnvironment.resolveAppName(infoDictionary: ["CFBundleDisplayName": "Display Name"]), "Display Name")
        XCTAssertEqual(AppEnvironment.resolveAppName(infoDictionary: ["CFBundleDisplayName": "", "CFBundleName": "Bundle Name"]), "Bundle Name")
        XCTAssertEqual(AppEnvironment.resolveAppName(infoDictionary: ["CFBundleName": "Bundle Name"]), "Bundle Name")
        XCTAssertEqual(AppEnvironment.resolveAppName(infoDictionary: nil), "MyTuist")
    }
}
