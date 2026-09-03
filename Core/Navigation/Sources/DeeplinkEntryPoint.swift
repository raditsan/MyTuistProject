import Foundation

public enum DeeplinkEntryPoint: Sendable, Hashable {
    case general
    case product(id: Int)
    case custom(name: String)
}
