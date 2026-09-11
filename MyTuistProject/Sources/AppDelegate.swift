import UIKit
import UserNotifications
import Combine
import CoreNotification
import CoreNavigation
import FactoryKit

public final class AppDelegate: NSObject, UIApplicationDelegate {
    @Injected(\.notificationService) private var notificationService
    @Injected(\.router) private var router

    private var cancellables = Set<AnyCancellable>()

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // 1. Daftarkan delegate ke UNUserNotificationCenter saat bukan test runner
        if NSClassFromString("XCTestCase") == nil {
            UNUserNotificationCenter.current().delegate = NotificationCenterDelegateHandler.shared
        }

        // 2. Pasang router listener untuk notifikasi yang dibuka oleh user
        setupNotificationRouting()

        // 3. Minta izin notifikasi & daftarkan APNs
        Task {
            let granted = try? await notificationService.requestAuthorization()
            if granted == true {
                await MainActor.run {
                    application.registerForRemoteNotifications()
                }
            }
        }

        return true
    }

    // MARK: - APNs Device Token Callback

    public func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hexToken = notificationService.formatDeviceToken(deviceToken)
        print("📲 APNs Device Token Berhasil Didapat: \(hexToken)")
    }

    public func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ Gagal mendaftar APNs: \(error.localizedDescription)")
    }

    // MARK: - Deep Link Auto Routing

    private func setupNotificationRouting() {
        notificationService.openedNotificationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] payload in
                print("🔔 Notifikasi dibuka: '\(payload.title)' (Action: \(payload.actionIdentifier ?? "default"))")

                // Jika payload memiliki URL deep link, arahkan langsung via AppRouter
                if let deepLink = payload.deepLinkURL {
                    print("🚀 Membuka rute Deep Link dari notifikasi: \(deepLink)")
                    self?.router.handle(url: deepLink)
                }
            }
            .store(in: &cancellables)
    }
}
