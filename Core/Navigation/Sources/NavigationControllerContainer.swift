import SwiftUI
import UIKit

// MARK: - NavigationControllerContainer

public struct NavigationControllerContainer: UIViewControllerRepresentable {
    public let navigationController: UINavigationController

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    public func makeUIViewController(context: Context) -> UINavigationController {
        return navigationController
    }

    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
