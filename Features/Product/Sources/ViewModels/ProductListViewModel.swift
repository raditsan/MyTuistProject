import Foundation
import Combine
import DomainProduct

public enum ViewState<T: Equatable>: Equatable {
    case idle
    case loading
    case success(T)
    case empty
    case failure(String)
}

@MainActor
public final class ProductListViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<[Product]> = .idle
    @Published public private(set) var categories: [String] = ["All"]
    @Published public var selectedCategory: String = "All"
    @Published public var searchQuery: String = ""

    private let getProductsUseCase: GetProductsUseCaseProtocol
    private let repository: ProductRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    public init(
        getProductsUseCase: GetProductsUseCaseProtocol,
        repository: ProductRepositoryProtocol
    ) {
        self.getProductsUseCase = getProductsUseCase
        self.repository = repository
        setupSearchDebounce()
    }

    private func setupSearchDebounce() {
        $searchQuery
            .dropFirst()
            .debounce(for: .milliseconds(400), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.fetchProducts()
                }
            }
            .store(in: &cancellables)
    }

    public func onAppear() async {
        if case .idle = state {
            async let categoriesTask: () = loadCategories()
            async let productsTask: () = fetchProducts()
            _ = await (categoriesTask, productsTask)
        }
    }

    public func selectCategory(_ category: String) async {
        guard selectedCategory != category else { return }
        selectedCategory = category
        await fetchProducts()
    }

    public func refresh() async {
        await fetchProducts()
    }

    public func fetchProducts() async {
        state = .loading
        do {
            let categoryFilter = (selectedCategory == "All") ? nil : selectedCategory
            let products = try await getProductsUseCase.execute(
                category: categoryFilter,
                searchQuery: searchQuery
            )

            if products.isEmpty {
                state = .empty
            } else {
                state = .success(products)
            }
        } catch {
            state = .failure(error.localizedDescription)
        }
    }

    public func loadCategories() async {
        do {
            let fetchedCategories = try await repository.getCategories()
            categories = ["All"] + fetchedCategories
        } catch {
            // Keep default "All" category if categories API fails
        }
    }
}
