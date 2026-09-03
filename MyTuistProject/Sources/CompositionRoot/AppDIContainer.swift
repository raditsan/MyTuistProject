import SwiftUI
import CoreNetwork
import CoreDesignSystem
import CoreNavigation
import DomainProduct
import DataProduct
import FeatureProduct
import FeatureProductDetail

@MainActor
public final class AppDIContainer: ObservableObject {
    public static let shared = AppDIContainer()

    // MARK: - Core Services
    public let networkClient: NetworkClientProtocol
    public let router: AppRouter

    // MARK: - Domain & Data Repositories
    public let productRemoteDataSource: ProductRemoteDataSourceProtocol
    public let productRepository: ProductRepositoryProtocol
    public let getProductsUseCase: GetProductsUseCaseProtocol
    public let getProductDetailUseCase: GetProductDetailUseCaseProtocol

    private init() {
        // 1. Initialize Core
        let client = URLSessionNetworkClient()
        self.networkClient = client
        self.router = AppRouter()

        // 2. Initialize Data Layer
        let remoteDataSource = ProductRemoteDataSource(client: client)
        self.productRemoteDataSource = remoteDataSource
        let repository = ProductRepository(remoteDataSource: remoteDataSource)
        self.productRepository = repository

        // 3. Initialize Domain Layer (Use Cases)
        self.getProductsUseCase = GetProductsUseCase(repository: repository)
        self.getProductDetailUseCase = GetProductDetailUseCase(repository: repository)
    }

    // MARK: - View Factories
    public func makeProductListView() -> some View {
        let viewModel = ProductListViewModel(
            getProductsUseCase: getProductsUseCase,
            repository: productRepository
        )
        return ProductListView(
            viewModel: viewModel,
            onSelectProduct: { [weak self] product in
                self?.router.navigate(to: AppRoute.productDetail(product))
            }
        )
    }

    public func makeProductDetailView(productId: Int) -> some View {
        let viewModel = ProductDetailViewModel(
            productId: productId,
            getProductDetailUseCase: getProductDetailUseCase
        )
        return ProductDetailView(viewModel: viewModel)
    }
}
