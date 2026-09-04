import SwiftUI
import CoreDesignSystem
import CoreNavigation
import FactoryKit

@MainActor
public struct FavoritesView: View {
    @StateObject private var viewModel = FavoritesViewModel()

    public init() {}

    public var body: some View {
        List(viewModel.items, id: \.self) { item in
            Text(item)
        }
        .navigationTitle("Favorit Saya")
        .onAppear {
            viewModel.loadFavorites()
        }
    }
}
