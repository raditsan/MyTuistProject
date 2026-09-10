import XCTest
import Combine
import FactoryKit
import CoreLocalization

@MainActor
final class LocalizationTests: XCTestCase {
    private var manager: LocalizationManager!

    override func setUp() {
        super.setUp()
        manager = LocalizationManager.shared
    }

    // MARK: - Factory DI Container
    func test_container_localizationManager() {
        let containerManager = Container.shared.localizationManager()
        XCTAssertNotNil(containerManager)
        XCTAssertTrue(containerManager === LocalizationManager.shared)
    }

    // MARK: - CoreLocalization Resources Bundle
    func test_coreLocalizationResources_bundle() {
        let bundle = CoreLocalizationResources.bundle
        XCTAssertNotNil(bundle)
        XCTAssertNotNil(manager.currentBundle)
    }

    // MARK: - AppLanguage Properties
    func test_appLanguageProperties() {
        for lang in AppLanguage.allCases {
            XCTAssertFalse(lang.id.isEmpty)
            XCTAssertFalse(lang.title.isEmpty)
            XCTAssertFalse(lang.flag.isEmpty)
            XCTAssertFalse(lang.shortCode.isEmpty)
        }

        XCTAssertEqual(AppLanguage.indonesian.id, "id")
        XCTAssertEqual(AppLanguage.indonesian.title, "Bahasa Indonesia")
        XCTAssertEqual(AppLanguage.indonesian.flag, "🇮🇩")
        XCTAssertEqual(AppLanguage.indonesian.shortCode, "ID")

        XCTAssertEqual(AppLanguage.english.id, "en")
        XCTAssertEqual(AppLanguage.english.title, "English")
        XCTAssertEqual(AppLanguage.english.flag, "🇬🇧")
        XCTAssertEqual(AppLanguage.english.shortCode, "EN")
    }

    // MARK: - LocalizationManager Advanced Behaviors
    func test_setLanguage_sameLanguage_noOp() {
        manager.setLanguage(.indonesian)
        let bundleBefore = manager.currentBundle
        manager.setLanguage(.indonesian)
        let bundleAfter = manager.currentBundle
        XCTAssertEqual(bundleBefore, bundleAfter)
    }

    func test_setLanguage_backgroundThread_postsNotification() {
        let exp = expectation(description: "languageDidChangeNotification")
        var receivedLanguage: AppLanguage?

        let cancellable = NotificationCenter.default.publisher(for: LocalizationManager.languageDidChangeNotification)
            .sink { notification in
                if let lang = notification.object as? AppLanguage {
                    receivedLanguage = lang
                    exp.fulfill()
                }
            }

        DispatchQueue.global(qos: .userInitiated).async {
            self.manager.setLanguage(.english)
        }

        wait(for: [exp], timeout: 2.0)
        cancellable.cancel()

        XCTAssertEqual(receivedLanguage, .english)
        XCTAssertEqual(manager.currentLanguage, .english)
    }

    func test_init_withCustomUserDefaults() {
        let defaultsSuite = "LocalizationTestsSuite"
        guard let userDefaults = UserDefaults(suiteName: defaultsSuite) else {
            XCTFail("Failed to create UserDefaults suite")
            return
        }
        userDefaults.removePersistentDomain(forName: defaultsSuite)

        // 1. Initialized with no saved language
        let defaultManager = LocalizationManager(userDefaults: userDefaults)
        XCTAssertNotNil(defaultManager.currentLanguage)

        // 2. Initialized with saved language 'en'
        userDefaults.set("en", forKey: "dev.tuist.MyTuistProject.selectedLanguage")
        let englishManager = LocalizationManager(userDefaults: userDefaults)
        XCTAssertEqual(englishManager.currentLanguage, .english)

        // 3. Initialized with saved language 'id'
        userDefaults.set("id", forKey: "dev.tuist.MyTuistProject.selectedLanguage")
        let indonesianManager = LocalizationManager(userDefaults: userDefaults)
        XCTAssertEqual(indonesianManager.currentLanguage, .indonesian)

        userDefaults.removePersistentDomain(forName: defaultsSuite)
    }

    func test_localized_methods() {
        manager.setLanguage(.indonesian)

        // Standard string
        let retryText = manager.localized("common.retry")
        XCTAssertEqual(retryText, "Coba Lagi")

        // Without variable args
        let plain = manager.localized("common.all")
        XCTAssertEqual(plain, "Semua")

        // With arguments formatting
        let formatted = manager.localized("product.detail.reviews_count", 42)
        XCTAssertEqual(formatted, "(42 ulasan)")

        // Non existent key fallback to key
        let unknownKey = "non_existent_localization_key"
        XCTAssertEqual(manager.localized(unknownKey), unknownKey)
    }

    // MARK: - Indonesian Translations
    func test_indonesianTranslations_areComplete() {
        manager.setLanguage(.indonesian)

        XCTAssertEqual(manager.currentLanguage, .indonesian)
        XCTAssertEqual(L10n.Common.appName, "MyTuistProject")
        XCTAssertEqual(L10n.Common.loading, "Memuat data...")
        XCTAssertEqual(L10n.Common.retry, "Coba Lagi")
        XCTAssertEqual(L10n.Common.all, "Semua")
        XCTAssertEqual(L10n.Product.Catalog.title, "Katalog Produk")
        XCTAssertEqual(L10n.Product.Catalog.searchPrompt, "Cari produk...")
        XCTAssertEqual(L10n.Product.Detail.title, "Detail Produk")
        XCTAssertEqual(L10n.Favorites.title, "Favorit Saya")
        XCTAssertEqual(L10n.Splash.subtitle, "Clean Architecture & Modular Engine")
        XCTAssertEqual(L10n.Profile.title, "Profil Saya")
        XCTAssertEqual(L10n.Profile.logout, "Keluar Akun")
    }

    // MARK: - English Translations
    func test_englishTranslations_areComplete() {
        manager.setLanguage(.english)

        XCTAssertEqual(manager.currentLanguage, .english)
        XCTAssertEqual(L10n.Common.appName, "MyTuistProject")
        XCTAssertEqual(L10n.Common.loading, "Loading data...")
        XCTAssertEqual(L10n.Common.retry, "Try Again")
        XCTAssertEqual(L10n.Common.all, "All")
        XCTAssertEqual(L10n.Product.Catalog.title, "Product Catalog")
        XCTAssertEqual(L10n.Product.Catalog.searchPrompt, "Search products...")
        XCTAssertEqual(L10n.Product.Detail.title, "Product Detail")
        XCTAssertEqual(L10n.Favorites.title, "My Favorites")
        XCTAssertEqual(L10n.Splash.subtitle, "Clean Architecture & Modular Engine")
        XCTAssertEqual(L10n.Profile.title, "My Profile")
        XCTAssertEqual(L10n.Profile.logout, "Log Out")
    }

    // MARK: - Dynamic Language Switching
    func test_dynamicLanguageSwitching() {
        manager.setLanguage(.indonesian)
        XCTAssertEqual(L10n.Product.Catalog.title, "Katalog Produk")
        XCTAssertEqual(L10n.Common.Error.title, "Terjadi Kesalahan")
        XCTAssertEqual(L10n.Profile.title, "Profil Saya")
        XCTAssertEqual(L10n.Profile.logout, "Keluar Akun")
        XCTAssertEqual(CoreLocalizationStrings.Profile.title, "Profil Saya")
        XCTAssertEqual(CoreLocalizationStrings.Common.retry, "Coba Lagi")

        manager.setLanguage(.english)
        XCTAssertEqual(L10n.Product.Catalog.title, "Product Catalog")
        XCTAssertEqual(L10n.Common.Error.title, "An Error Occurred")
        XCTAssertEqual(L10n.Profile.title, "My Profile")
        XCTAssertEqual(L10n.Profile.logout, "Log Out")
        XCTAssertEqual(CoreLocalizationStrings.Profile.title, "My Profile")
        XCTAssertEqual(CoreLocalizationStrings.Common.retry, "Try Again")
    }

    // MARK: - Comprehensive L10n Key Coverage
    func test_l10n_common_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Common.all.isEmpty)
        XCTAssertFalse(L10n.Common.appName.isEmpty)
        XCTAssertFalse(L10n.Common.back.isEmpty)
        XCTAssertFalse(L10n.Common.cancel.isEmpty)
        XCTAssertFalse(L10n.Common.close.isEmpty)
        XCTAssertFalse(L10n.Common.loading.isEmpty)
        XCTAssertFalse(L10n.Common.retry.isEmpty)
        XCTAssertFalse(L10n.Common.search.isEmpty)
        XCTAssertFalse(L10n.Common.Error.title.isEmpty)
    }

    func test_l10n_deeplink_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Deeplink.Button.back.isEmpty)
        XCTAssertFalse(L10n.Deeplink.Button.retry.isEmpty)
        XCTAssertFalse(L10n.Deeplink.Error.title.isEmpty)
        XCTAssertFalse(L10n.Deeplink.Loading.generic.isEmpty)
        XCTAssertFalse(L10n.Deeplink.Loading.process.isEmpty)
        XCTAssertFalse(L10n.Deeplink.Loading.product(10).isEmpty)
    }

    func test_l10n_error_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Error.decoding("JSONError").isEmpty)
        XCTAssertFalse(L10n.Error.forbidden.isEmpty)
        XCTAssertFalse(L10n.Error.invalidResponse(404).isEmpty)
        XCTAssertFalse(L10n.Error.invalidUrl.isEmpty)
        XCTAssertFalse(L10n.Error.noData.isEmpty)
        XCTAssertFalse(L10n.Error.noInternet.isEmpty)
        XCTAssertFalse(L10n.Error.notFound.isEmpty)
        XCTAssertFalse(L10n.Error.rateLimited.isEmpty)
        XCTAssertFalse(L10n.Error.server("500 Internal").isEmpty)
        XCTAssertFalse(L10n.Error.timeout.isEmpty)
        XCTAssertFalse(L10n.Error.unauthorized.isEmpty)
        XCTAssertFalse(L10n.Error.unknown("Unexpected").isEmpty)
    }

    func test_l10n_favorites_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Favorites.emptySubtitle.isEmpty)
        XCTAssertFalse(L10n.Favorites.emptyTitle.isEmpty)
        XCTAssertFalse(L10n.Favorites.title.isEmpty)
    }

    func test_l10n_language_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Language.current.isEmpty)
        XCTAssertFalse(L10n.Language.english.isEmpty)
        XCTAssertFalse(L10n.Language.indonesian.isEmpty)
        XCTAssertFalse(L10n.Language.title.isEmpty)
    }

    func test_l10n_permission_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Permission.Camera.description.isEmpty)
        XCTAssertFalse(L10n.Permission.Camera.title.isEmpty)
        XCTAssertFalse(L10n.Permission.Denied.message.isEmpty)
        XCTAssertFalse(L10n.Permission.Location.description.isEmpty)
        XCTAssertFalse(L10n.Permission.Location.title.isEmpty)
        XCTAssertFalse(L10n.Permission.Notification.description.isEmpty)
        XCTAssertFalse(L10n.Permission.Notification.title.isEmpty)
        XCTAssertFalse(L10n.Permission.Settings.button.isEmpty)
    }

    func test_l10n_product_allKeys() {
        manager.setLanguage(.indonesian)
        // Catalog
        XCTAssertFalse(L10n.Product.Catalog.emptySubtitle.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.emptyTitle.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.errorTitle.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.favoriteMenu.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.loading.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.searchPrompt.isEmpty)
        XCTAssertFalse(L10n.Product.Catalog.title.isEmpty)

        // Detail
        XCTAssertFalse(L10n.Product.Detail.errorTitle.isEmpty)
        XCTAssertFalse(L10n.Product.Detail.loading.isEmpty)
        XCTAssertFalse(L10n.Product.Detail.notFoundMessage.isEmpty)
        XCTAssertFalse(L10n.Product.Detail.notFoundTitle.isEmpty)
        XCTAssertFalse(L10n.Product.Detail.reviewsCount(5).isEmpty)
        XCTAssertFalse(L10n.Product.Detail.sectionDescription.isEmpty)
        XCTAssertFalse(L10n.Product.Detail.title.isEmpty)
    }

    func test_l10n_profile_and_splash_allKeys() {
        manager.setLanguage(.indonesian)
        XCTAssertFalse(L10n.Profile.logout.isEmpty)
        XCTAssertFalse(L10n.Profile.title.isEmpty)
        XCTAssertFalse(L10n.Splash.subtitle.isEmpty)
    }
}
