import XCTest
import UserNotifications
@testable import CoreNotification

final class NotificationPayloadTests: XCTestCase {
    func test_payload_memberwiseInit_and_equality() {
        let id = "test-notif-1"
        let title = "Diskon Akhir Tahun!"
        let subtitle = "Hingga 70%"
        let body = "Segera checkout produk impianmu sekarang."
        let badge: NSNumber = 3
        let url = URL(string: "mytuist://product/42")!
        let userInfo = ["source": "campaign_december"]

        let payload = NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            badge: badge,
            sound: .defaultSound,
            deepLinkURL: url,
            actionIdentifier: "OPEN_ACTION",
            userInfo: userInfo
        )

        XCTAssertEqual(payload.id, id)
        XCTAssertEqual(payload.title, title)
        XCTAssertEqual(payload.subtitle, subtitle)
        XCTAssertEqual(payload.body, body)
        XCTAssertEqual(payload.badge, badge)
        XCTAssertEqual(payload.sound, .defaultSound)
        XCTAssertEqual(payload.deepLinkURL, url)
        XCTAssertEqual(payload.actionIdentifier, "OPEN_ACTION")
        XCTAssertEqual(payload.userInfo["source"], "campaign_december")

        let identicalPayload = NotificationPayload(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            badge: badge,
            sound: .defaultSound,
            deepLinkURL: url,
            actionIdentifier: "OPEN_ACTION",
            userInfo: userInfo
        )
        XCTAssertEqual(payload, identicalPayload)
    }

    func test_extractDeepLinkURL_fromVariousCandidateKeys() {
        let testCases: [[String: String]] = [
            ["deeplink": "mytuist://favorites"],
            ["deep_link": "mytuist://product/10"],
            ["url": "mytuist://cart"],
            ["link": "mytuist://profile"],
            ["target_url": "mytuist://search?q=shoes"],
            ["route": "mytuist://splash"]
        ]

        for dictionary in testCases {
            let extracted = NotificationPayload.extractDeepLinkURL(from: dictionary)
            XCTAssertNotNil(extracted, "Gagal mengekstrak URL dari dictionary: \(dictionary)")
        }

        // Test with whitespace
        let whitespaceDict = ["deeplink": "  mytuist://cart  \n"]
        XCTAssertEqual(
            NotificationPayload.extractDeepLinkURL(from: whitespaceDict)?.absoluteString,
            "mytuist://cart"
        )

        // Test empty/invalid
        let emptyDict: [String: String] = ["deeplink": "   ", "other": "value"]
        XCTAssertNil(NotificationPayload.extractDeepLinkURL(from: emptyDict))

        let noKeyDict: [String: String] = ["foo": "bar"]
        XCTAssertNil(NotificationPayload.extractDeepLinkURL(from: noKeyDict))
    }

    func test_payload_initFromUNNotificationContent() {
        let content = UNMutableNotificationContent()
        content.title = "Pesanan Dikirim"
        content.subtitle = "No Resi: JNE12345"
        content.body = "Paket Anda sedang dalam perjalanan."
        content.badge = 1
        content.sound = UNNotificationSound.default
        content.userInfo = [
            "deeplink": "mytuist://product/99",
            "order_id": 999
        ]

        let payload = NotificationPayload(id: "order-ship-1", content: content, actionIdentifier: "VIEW_ORDER")

        XCTAssertEqual(payload.id, "order-ship-1")
        XCTAssertEqual(payload.title, "Pesanan Dikirim")
        XCTAssertEqual(payload.subtitle, "No Resi: JNE12345")
        XCTAssertEqual(payload.body, "Paket Anda sedang dalam perjalanan.")
        XCTAssertEqual(payload.badge, 1)
        XCTAssertEqual(payload.sound, .defaultSound)
        XCTAssertEqual(payload.deepLinkURL?.absoluteString, "mytuist://product/99")
        XCTAssertEqual(payload.actionIdentifier, "VIEW_ORDER")
        XCTAssertEqual(payload.userInfo["order_id"], "999")
    }

    func test_notificationSound_variants() {
        let def = NotificationSound.defaultSound
        XCTAssertNotNil(def.unSound)

        let none = NotificationSound.none
        XCTAssertNil(none.unSound)

        let named = NotificationSound.named("custom_chime.wav")
        XCTAssertNotNil(named.unSound)
    }

    func test_notificationAction_and_options() {
        let action = NotificationAction(
            identifier: "CHECKOUT",
            title: "Beli Sekarang",
            options: [.foreground, .authenticationRequired]
        )

        XCTAssertEqual(action.identifier, "CHECKOUT")
        XCTAssertEqual(action.title, "Beli Sekarang")
        XCTAssertTrue(action.options.contains(.foreground))
        XCTAssertTrue(action.options.contains(.authenticationRequired))
        XCTAssertFalse(action.options.contains(.destructive))

        let unAction = action.makeUNNotificationAction()
        XCTAssertEqual(unAction.identifier, "CHECKOUT")
        XCTAssertEqual(unAction.title, "Beli Sekarang")
    }

    func test_notificationCategory_withPlaceholder() {
        let action = NotificationAction(identifier: "DISMISS", title: "Tutup", options: [.destructive])
        let categoryWithPlaceholder = NotificationCategory(
            identifier: "PROMO_CATEGORY",
            actions: [action],
            intentIdentifiers: ["intent.promo"],
            hiddenPreviewsBodyPlaceholder: "Buka notifikasi untuk melihat promo"
        )

        let unCategory1 = categoryWithPlaceholder.makeUNNotificationCategory()
        XCTAssertEqual(unCategory1.identifier, "PROMO_CATEGORY")
        XCTAssertEqual(unCategory1.actions.count, 1)
        XCTAssertEqual(unCategory1.hiddenPreviewsBodyPlaceholder, "Buka notifikasi untuk melihat promo")

        let categoryNoPlaceholder = NotificationCategory(
            identifier: "SIMPLE_CATEGORY",
            actions: [action]
        )
        let unCategory2 = categoryNoPlaceholder.makeUNNotificationCategory()
        XCTAssertEqual(unCategory2.identifier, "SIMPLE_CATEGORY")
    }

    func test_deviceTokenFormatting() {
        let service = NotificationService.shared
        // 32 bytes sample token (256-bit standard APNs device token)
        let bytes: [UInt8] = [
            0x12, 0x34, 0x56, 0x78, 0x90, 0xab, 0xcd, 0xef,
            0xfe, 0xdc, 0xba, 0x09, 0x87, 0x65, 0x43, 0x21,
            0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11,
            0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99
        ]
        let tokenData = Data(bytes)
        let formatted = service.formatDeviceToken(tokenData)

        XCTAssertEqual(formatted.count, 64)
        XCTAssertEqual(formatted, "1234567890abcdeffedcba0987654321aabbccddeeff00112233445566778899")
    }
}
