import Foundation
import FactoryKit

extension Container {
    public var networkClient: Factory<NetworkClientProtocol> {
        self { URLSessionNetworkClient() }.singleton
    }
}
