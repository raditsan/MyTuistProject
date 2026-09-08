import SwiftUI
import CoreDesignSystem
import CoreNavigation
import CoreLocalization
import FactoryKit

@MainActor
public struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @ObservedObject private var localizationManager = LocalizationManager.shared

    public init() {}

    public var body: some View {
        List(viewModel.items, id: \.self) { item in
            Text(item)
        }
        .navigationTitle(L10n.Favorites.title)
        .onAppear {
            viewModel.loadFavorites()
        }
    }
}
