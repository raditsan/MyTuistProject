import Foundation
import CoreLocalization

public enum PermissionType: String, CaseIterable, Sendable, Hashable {
    case camera
    case location
    case notification
}

public extension PermissionType {
    var title: String {
        switch self {
        case .camera:
            return L10n.Permission.Camera.title
        case .location:
            return L10n.Permission.Location.title
        case .notification:
            return L10n.Permission.Notification.title
        }
    }

    var description: String {
        switch self {
        case .camera:
            return L10n.Permission.Camera.description
        case .location:
            return L10n.Permission.Location.description
        case .notification:
            return L10n.Permission.Notification.description
        }
    }
}

public enum PermissionStatus: String, Sendable, Equatable {
    case granted
    case denied
    case restricted
    case notDetermined
}

public typealias PermissionResult = [PermissionType: PermissionStatus]

public extension Dictionary where Key == PermissionType, Value == PermissionStatus {
    var allGranted: Bool {
        !isEmpty && values.allSatisfy { $0 == .granted }
    }

    var anyDenied: Bool {
        values.contains { $0 == .denied }
    }

    func isGranted(_ type: PermissionType) -> Bool {
        self[type] == .granted
    }
}
