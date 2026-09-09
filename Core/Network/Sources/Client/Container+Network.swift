import Foundation
import FactoryKit
import Moya

extension Container {

    // MARK: - Network Plugins

    /// Plugins applied to all network requests, ordered by execution.
    /// Override in tests to inject mock plugins.
    public var networkPlugins: Factory<[PluginType]> {
        self {
            var plugins: [PluginType] = []

            // Global application metadata & headers
            plugins.append(HeaderPlugin.defaultAppMetadata)

            // Logging: auto-adjust based on environment
            if AppEnvironment.isDevelopment {
                plugins.append(LoggingPlugin(logLevel: .verbose))
            } else if AppEnvironment.isUAT {
                plugins.append(LoggingPlugin(logLevel: .standard))
            }
            // No logging in production

            // Error handling: always active
            plugins.append(ErrorPlugin(errorHandler: AppEnvironment.isProduction ? nil : ConsoleErrorHandler()))

            // Retry: always active
            plugins.append(RetryPlugin())

            return plugins
        }.singleton
    }

    // MARK: - Network Configuration

    /// Network configuration adjusted per environment.
    public var networkConfiguration: Factory<NetworkConfiguration> {
        self {
            if AppEnvironment.isDevelopment {
                return .development
            } else if AppEnvironment.isProduction {
                return .production
            }
            return .default
        }.singleton
    }

    // MARK: - Network Client

    /// The main network client. Uses plugins and configuration from the container.
    public var networkClient: Factory<NetworkClientProtocol> {
        self {
            MoyaNetworkClient(
                plugins: self.networkPlugins(),
                configuration: self.networkConfiguration()
            )
        }.singleton
    }
}
