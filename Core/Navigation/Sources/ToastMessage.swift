import SwiftUI

public struct ToastMessage: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let message: String?
    public let style: ToastStyle
    public let duration: TimeInterval

    public enum ToastStyle: Sendable {
        case info
        case success
        case warning
        case error

        public var color: Color {
            switch self {
            case .info:    return .blue
            case .success: return .green
            case .warning: return .orange
            case .error:   return .red
            }
        }

        public var iconName: String {
            switch self {
            case .info:    return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error:   return "xmark.octagon.fill"
            }
        }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        message: String? = nil,
        style: ToastStyle = .info,
        duration: TimeInterval = 3.0
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.style = style
        self.duration = duration
    }
}
