import SwiftUI
import DomainProduct
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import FactoryKit

@MainActor
public struct ProductListView: View {
    @Injected(\.router) private var router
    @StateObject private var viewModel: ProductListViewModel
    @InjectedObject(\.localizationManager) private var localizationManager: LocalizationManager

    private let columns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
    ]

    public init() {
        _viewModel = StateObject(wrappedValue: ProductListViewModel())
    }

    public init(viewModel: ProductListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Category Filter Bar
            categoryFilterBar

            // Content State
            contentView
        }
        .background(DesignTokens.Colors.background.ignoresSafeArea())
        .navigationTitle(L10n.Product.Catalog.title)
        .searchable(text: $viewModel.searchQuery, prompt: L10n.Product.Catalog.searchPrompt)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    languageMenu

                    Button {
                        router.navigate(.favorites(.list))
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .accessibilityLabel(L10n.Product.Catalog.favoriteMenu)
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }

    // MARK: - Language Selector Menu
    @ViewBuilder
    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button {
                    localizationManager.setLanguage(lang)
                } label: {
                    HStack {
                        Text("\(lang.flag) \(lang.title)")
                        if localizationManager.currentLanguage == lang {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(localizationManager.currentLanguage.flag)
                Text(localizationManager.currentLanguage.shortCode)
                    .font(.caption.bold())
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(DesignTokens.Colors.cardBackground)
            .cornerRadius(DesignTokens.CornerRadius.sm)
        }
    }

    // MARK: - Category Filter Bar
    @ViewBuilder
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.categories, id: \.self) { category in
                    let isSelected = viewModel.selectedCategory == category
                    let categoryTitle = category == "All" ? L10n.Common.all : category.capitalized
                    Button(action: {
                        Task {
                            await viewModel.selectCategory(category)
                        }
                    }) {
                        Text(categoryTitle)
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.cardBackground
                            )
                            .cornerRadius(DesignTokens.CornerRadius.full)
                            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
    }

    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            LoadingView(message: L10n.Product.Catalog.loading)
        case .empty:
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 48))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                Text(L10n.Product.Catalog.emptyTitle)
                    .font(.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                Text(L10n.Product.Catalog.emptySubtitle)
                    .font(.subheadline)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        case .failure(let errorMessage):
            ErrorView(
                title: L10n.Product.Catalog.errorTitle,
                message: errorMessage,
                retryAction: {
                    Task { await viewModel.refresh() }
                }
            )
        case .success(let products):
            ScrollView {
                LazyVGrid(columns: columns, spacing: DesignTokens.Spacing.md) {
                    ForEach(products) { product in
                        Button {
                            router.navigate(.product(.detail(.init(product: product))))
                        } label: {
                            ProductCardView(product: product)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}
