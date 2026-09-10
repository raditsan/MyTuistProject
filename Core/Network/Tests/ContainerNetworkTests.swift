import XCTest
import FactoryKit
import Moya
@testable import CoreNetwork

final class ContainerNetworkTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AppEnvironment.environmentOverride = nil
        Container.shared.networkPlugins.reset()
        Container.shared.networkConfiguration.reset()
        Container.shared.networkClient.reset()
    }

    override func tearDown() {
        AppEnvironment.environmentOverride = nil
        Container.shared.networkPlugins.reset()
        Container.shared.networkConfiguration.reset()
        Container.shared.networkClient.reset()
        super.tearDown()
    }

    func test_networkPlugins_development() {
        AppEnvironment.environmentOverride = .dev
        Container.shared.networkPlugins.reset()

        let plugins = Container.shared.networkPlugins()
        XCTAssertFalse(plugins.isEmpty)
        // Should contain HeaderPlugin, LoggingPlugin (.verbose), ErrorPlugin (with ConsoleErrorHandler), RetryPlugin
        XCTAssertTrue(plugins.contains { $0 is HeaderPlugin })
        XCTAssertTrue(plugins.contains { $0 is LoggingPlugin })
        XCTAssertTrue(plugins.contains { $0 is ErrorPlugin })
        XCTAssertTrue(plugins.contains { $0 is RetryPlugin })
    }

    func test_networkPlugins_uat() {
        AppEnvironment.environmentOverride = .uat
        Container.shared.networkPlugins.reset()

        let plugins = Container.shared.networkPlugins()
        XCTAssertFalse(plugins.isEmpty)
        XCTAssertTrue(plugins.contains { $0 is LoggingPlugin })
    }

    func test_networkPlugins_production() {
        AppEnvironment.environmentOverride = .prod
        Container.shared.networkPlugins.reset()

        let plugins = Container.shared.networkPlugins()
        XCTAssertFalse(plugins.isEmpty)
        // Production: no LoggingPlugin
        XCTAssertFalse(plugins.contains { $0 is LoggingPlugin })
        XCTAssertTrue(plugins.contains { $0 is ErrorPlugin })
        XCTAssertTrue(plugins.contains { $0 is RetryPlugin })
    }

    func test_networkConfiguration_environments() {
        // Dev
        AppEnvironment.environmentOverride = .dev
        Container.shared.networkConfiguration.reset()
        let devConfig = Container.shared.networkConfiguration()
        XCTAssertEqual(devConfig.timeoutInterval, NetworkConfiguration.development.timeoutInterval)

        // Prod
        AppEnvironment.environmentOverride = .prod
        Container.shared.networkConfiguration.reset()
        let prodConfig = Container.shared.networkConfiguration()
        XCTAssertEqual(prodConfig.timeoutInterval, NetworkConfiguration.production.timeoutInterval)

        // UAT (fallback to default)
        AppEnvironment.environmentOverride = .uat
        Container.shared.networkConfiguration.reset()
        let uatConfig = Container.shared.networkConfiguration()
        XCTAssertEqual(uatConfig.timeoutInterval, NetworkConfiguration.default.timeoutInterval)
    }

    func test_networkClient_resolvesSingleton() {
        let client1 = Container.shared.networkClient()
        let client2 = Container.shared.networkClient()

        XCTAssertNotNil(client1)
        XCTAssertTrue(client1 as AnyObject === client2 as AnyObject)
    }
}
