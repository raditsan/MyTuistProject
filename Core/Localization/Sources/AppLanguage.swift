import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case indonesian = "id"
    case english = "en"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .indonesian:
            return "Bahasa Indonesia"
        case .english:
            return "English"
        }
    }

    public var flag: String {
        switch self {
        case .indonesian:
            return "🇮🇩"
        case .english:
            return "🇬🇧"
        }
    }

    public var shortCode: String {
        switch self {
        case .indonesian:
            return "ID"
        case .english:
            return "EN"
        }
    }
}
