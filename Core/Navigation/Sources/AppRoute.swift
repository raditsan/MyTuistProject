import Foundation
import DomainProduct

// MARK: - AppRoute
public enum AppRoute: Hashable, Sendable {
    case productList
    case productDetail(Product)
    case productDetailById(Int)
}
