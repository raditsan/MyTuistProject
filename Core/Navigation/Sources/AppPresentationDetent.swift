import SwiftUI
import UIKit

// MARK: - AppPresentationDetent

/// Platform-agnostic presentation detents supporting SwiftUI/UIKit on iOS 15+.
public enum AppPresentationDetent: Hashable, Sendable {
    case medium
    case large
    case fraction(CGFloat)
    case height(CGFloat)

    @available(iOS 15.0, *)
    public var uiKitDetent: UISheetPresentationController.Detent {
        switch self {
        case .medium:
            return .medium()
        case .large:
            return .large()
        case .fraction(let fraction):
            if #available(iOS 16.0, *) {
                let id = UISheetPresentationController.Detent.Identifier("fraction_\(fraction)")
                return .custom(identifier: id) { context in
                    return context.maximumDetentValue * fraction
                }
            } else {
                return fraction <= 0.6 ? .medium() : .large()
            }
        case .height(let height):
            if #available(iOS 16.0, *) {
                let id = UISheetPresentationController.Detent.Identifier("height_\(height)")
                return .custom(identifier: id) { _ in
                    return height
                }
            } else {
                return height <= 450 ? .medium() : .large()
            }
        }
    }

    @available(iOS 15.0, *)
    public var uiKitIdentifier: UISheetPresentationController.Detent.Identifier? {
        switch self {
        case .medium:
            return .medium
        case .large:
            return .large
        case .fraction(let fraction):
            if #available(iOS 16.0, *) {
                return UISheetPresentationController.Detent.Identifier("fraction_\(fraction)")
            }
            return fraction <= 0.6 ? .medium : .large
        case .height(let height):
            if #available(iOS 16.0, *) {
                return UISheetPresentationController.Detent.Identifier("height_\(height)")
            }
            return height <= 450 ? .medium : .large
        }
    }
}

// MARK: - SheetDragIndicator

public enum SheetDragIndicator: Sendable {
    case automatic
    case visible
    case hidden
}

// MARK: - SheetConfiguration

public struct SheetConfiguration: Sendable {
    public var detents: [AppPresentationDetent]
    public var selectedDetent: AppPresentationDetent?
    public var dragIndicator: SheetDragIndicator
    public var cornerRadius: CGFloat?
    public var largestUndimmedDetent: AppPresentationDetent?
    public var isTransparent: Bool

    public init(
        detents: [AppPresentationDetent] = [.large],
        selectedDetent: AppPresentationDetent? = nil,
        dragIndicator: SheetDragIndicator = .automatic,
        cornerRadius: CGFloat? = nil,
        largestUndimmedDetent: AppPresentationDetent? = nil,
        isTransparent: Bool = false
    ) {
        self.detents = detents
        self.selectedDetent = selectedDetent
        self.dragIndicator = dragIndicator
        self.cornerRadius = cornerRadius
        self.largestUndimmedDetent = largestUndimmedDetent
        self.isTransparent = isTransparent
    }

    public static var `default`: SheetConfiguration {
        SheetConfiguration()
    }

    public static func detents(
        _ detents: [AppPresentationDetent],
        selectedDetent: AppPresentationDetent? = nil,
        dragIndicator: SheetDragIndicator = .automatic,
        cornerRadius: CGFloat? = nil,
        largestUndimmedDetent: AppPresentationDetent? = nil,
        isTransparent: Bool = false
    ) -> SheetConfiguration {
        SheetConfiguration(
            detents: detents,
            selectedDetent: selectedDetent,
            dragIndicator: dragIndicator,
            cornerRadius: cornerRadius,
            largestUndimmedDetent: largestUndimmedDetent,
            isTransparent: isTransparent
        )
    }

    public static func transparent(
        detents: [AppPresentationDetent] = [.large],
        selectedDetent: AppPresentationDetent? = nil,
        dragIndicator: SheetDragIndicator = .automatic,
        cornerRadius: CGFloat? = nil,
        largestUndimmedDetent: AppPresentationDetent? = nil
    ) -> SheetConfiguration {
        SheetConfiguration(
            detents: detents,
            selectedDetent: selectedDetent,
            dragIndicator: dragIndicator,
            cornerRadius: cornerRadius,
            largestUndimmedDetent: largestUndimmedDetent,
            isTransparent: true
        )
    }
}

public typealias SheetDetent = AppPresentationDetent
