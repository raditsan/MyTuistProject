import Foundation
import AVFoundation
import CoreLocation
import UserNotifications

public protocol PermissionHandlerProtocol: Sendable {
    func check() async -> PermissionStatus
    func request() async -> PermissionStatus
}

// MARK: - Camera Permission Handler

public final class CameraPermissionHandler: PermissionHandlerProtocol, @unchecked Sendable {
    public init() {}

    public func check() async -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    public func request() async -> PermissionStatus {
        let current = await check()
        guard current == .notDetermined else { return current }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .granted : .denied
    }
}

// MARK: - Location Permission Handler

@MainActor
final class LocationDelegateHelper: NSObject, CLLocationManagerDelegate {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<PermissionStatus, Never>?
    private var customStatus: CLAuthorizationStatus?

    init(manager: CLLocationManager = CLLocationManager(), customStatus: CLAuthorizationStatus? = nil) {
        self.manager = manager
        self.customStatus = customStatus
        super.init()
        manager.delegate = self
    }

    func checkStatus() -> PermissionStatus {
        let authStatus = customStatus ?? manager.authorizationStatus
        switch authStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            return .granted
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> PermissionStatus {
        let current = checkStatus()
        guard current == .notDetermined else { return current }

        return await withCheckedContinuation { cont in
            self.continuation = cont
            self.manager.requestWhenInUseAuthorization()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = checkStatus()
        if status != .notDetermined, let cont = continuation {
            continuation = nil
            cont.resume(returning: status)
        }
    }
}

public final class LocationPermissionHandler: PermissionHandlerProtocol, @unchecked Sendable {
    private var helper: LocationDelegateHelper?
    private let customStatus: CLAuthorizationStatus?

    public init(customStatus: CLAuthorizationStatus? = nil) {
        self.customStatus = customStatus
    }

    @MainActor
    private func getHelper() -> LocationDelegateHelper {
        if let helper = helper {
            return helper
        }
        let newHelper = LocationDelegateHelper(customStatus: customStatus)
        self.helper = newHelper
        return newHelper
    }

    @MainActor
    private func performCheck() -> PermissionStatus {
        getHelper().checkStatus()
    }

    @MainActor
    private func performRequest() async -> PermissionStatus {
        await getHelper().requestAuthorization()
    }

    public func check() async -> PermissionStatus {
        await performCheck()
    }

    public func request() async -> PermissionStatus {
        await performRequest()
    }
}

// MARK: - Notification Permission Handler

public final class NotificationPermissionHandler: PermissionHandlerProtocol, @unchecked Sendable {
    private let centerProvider: (@Sendable () -> UNUserNotificationCenter)?
    private let customStatusProvider: (@Sendable () async -> UNAuthorizationStatus)?
    private let customRequestProvider: (@Sendable () async throws -> Bool)?

    public init(center: UNUserNotificationCenter? = nil) {
        if let center = center {
            self.centerProvider = { center }
        } else {
            self.centerProvider = nil
        }
        self.customStatusProvider = nil
        self.customRequestProvider = nil
    }

    public init(centerProvider: @escaping @Sendable () -> UNUserNotificationCenter) {
        self.centerProvider = centerProvider
        self.customStatusProvider = nil
        self.customRequestProvider = nil
    }

    public init(
        statusProvider: (@Sendable () async -> UNAuthorizationStatus)? = nil,
        requestProvider: (@Sendable () async throws -> Bool)? = nil
    ) {
        self.centerProvider = nil
        self.customStatusProvider = statusProvider
        self.customRequestProvider = requestProvider
    }

    private func getCenter() -> UNUserNotificationCenter? {
        if let provider = centerProvider {
            return provider()
        }
        guard Bundle.main.bundleURL.pathExtension == "app" else {
            return nil
        }
        return UNUserNotificationCenter.current()
    }

    public func check() async -> PermissionStatus {
        let authStatus: UNAuthorizationStatus
        if let customStatusProvider = customStatusProvider {
            authStatus = await customStatusProvider()
        } else {
            guard let center = getCenter() else {
                return .notDetermined
            }
            let settings = await center.notificationSettings()
            authStatus = settings.authorizationStatus
        }

        switch authStatus {
        case .authorized, .provisional, .ephemeral:
            return .granted
        case .denied:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    public func request() async -> PermissionStatus {
        let current = await check()
        guard current == .notDetermined else { return current }

        if let customRequestProvider = customRequestProvider {
            do {
                let granted = try await customRequestProvider()
                return granted ? .granted : .denied
            } catch {
                return .denied
            }
        }

        guard let center = getCenter() else {
            return .notDetermined
        }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted ? .granted : .denied
        } catch {
            return .denied
        }
    }
}
