import Foundation
import Combine

public protocol LocalizationManagerProtocol: AnyObject, Sendable {
    var currentLanguage: AppLanguage { get }
    func setLanguage(_ language: AppLanguage)
    func localized(_ key: String) -> String
    func localized(_ key: String, _ args: CVarArg...) -> String
}

public final class LocalizationManager: ObservableObject, LocalizationManagerProtocol, @unchecked Sendable {
    public static let shared = LocalizationManager()

    public static let languageDidChangeNotification = Notification.Name("AppLanguageDidChangeNotification")
    private let userDefaultsKey = "dev.tuist.MyTuistProject.selectedLanguage"

    private let lock = NSLock()
    private var activeLanguage: AppLanguage
    private var activeBundle: Bundle?

    public var currentBundle: Bundle? {
        lock.lock()
        defer { lock.unlock() }
        return activeBundle
    }

    @Published public private(set) var currentLanguage: AppLanguage

    public init(userDefaults: UserDefaults = .standard) {
        let initialLang: AppLanguage
        if let savedRawValue = userDefaults.string(forKey: "dev.tuist.MyTuistProject.selectedLanguage"),
           let savedLanguage = AppLanguage(rawValue: savedRawValue) {
            initialLang = savedLanguage
        } else {
            let preferredLanguage = Locale.preferredLanguages.first?.lowercased() ?? ""
            initialLang = preferredLanguage.hasPrefix("id") ? .indonesian : .english
        }
        self.activeLanguage = initialLang
        self.currentLanguage = initialLang
        self.activeBundle = Self.loadBundle(for: initialLang)
    }

    public func setLanguage(_ language: AppLanguage) {
        lock.lock()
        guard language != activeLanguage else {
            lock.unlock()
            return
        }
        activeLanguage = language
        activeBundle = Self.loadBundle(for: language)
        lock.unlock()

        UserDefaults.standard.set(language.rawValue, forKey: userDefaultsKey)

        if Thread.isMainThread {
            self.currentLanguage = language
            NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: language)
        } else {
            DispatchQueue.main.async {
                self.currentLanguage = language
                NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: language)
            }
        }
    }

    public func localized(_ key: String) -> String {
        lock.lock()
        let bundle = activeBundle ?? Bundle.module
        lock.unlock()
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    public func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        guard !args.isEmpty else { return format }
        lock.lock()
        let lang = activeLanguage
        lock.unlock()
        return String(format: format, locale: Locale(identifier: lang.rawValue), arguments: args)
    }

    private static func loadBundle(for language: AppLanguage) -> Bundle {
        let baseBundle = Bundle.module
        if let path = baseBundle.path(forResource: language.rawValue, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            return languageBundle
        }
        return baseBundle
    }
}
