import XCTest
@testable import CoreLocalization

@MainActor
final class LocalizationTests: XCTestCase {
    private var manager: LocalizationManager!

    override func setUp() {
        super.setUp()
        manager = LocalizationManager.shared
    }

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

    func test_argumentsFormatting() {
        manager.setLanguage(.indonesian)
        XCTAssertEqual(L10n.Product.Detail.reviewsCount(25), "(25 ulasan)")
        XCTAssertEqual(L10n.Deeplink.Loading.product(10), "Memuat detail produk #10...")
        XCTAssertEqual(L10n.Error.invalidResponse(404), "Respon server tidak valid (Status code: 404).")

        manager.setLanguage(.english)
        XCTAssertEqual(L10n.Product.Detail.reviewsCount(25), "(25 reviews)")
        XCTAssertEqual(L10n.Deeplink.Loading.product(10), "Loading product details #10...")
        XCTAssertEqual(L10n.Error.invalidResponse(404), "Invalid server response (Status code: 404).")
    }

    func test_appLanguageProperties() {
        XCTAssertEqual(AppLanguage.indonesian.title, "Bahasa Indonesia")
        XCTAssertEqual(AppLanguage.indonesian.flag, "🇮🇩")
        XCTAssertEqual(AppLanguage.indonesian.shortCode, "ID")

        XCTAssertEqual(AppLanguage.english.title, "English")
        XCTAssertEqual(AppLanguage.english.flag, "🇬🇧")
        XCTAssertEqual(AppLanguage.english.shortCode, "EN")
    }
}
