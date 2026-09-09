import Foundation
@_exported import Moya

public typealias APIEndpoint = TargetType

public extension TargetType {
    /// Default JSON headers for convenience.
    var defaultHeaders: [String: String] {
        ["Content-Type": "application/json", "Accept": "application/json"]
    }
}
