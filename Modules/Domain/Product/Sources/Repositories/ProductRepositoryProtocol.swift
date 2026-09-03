import Foundation

public protocol ProductRepositoryProtocol: Sendable {
    func getProducts() async throws -> [Product]
    func getProductDetail(id: Int) async throws -> Product
    func getCategories() async throws -> [String]
}
