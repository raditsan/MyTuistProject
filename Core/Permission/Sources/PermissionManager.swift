import Foundation
import UIKit

public protocol PermissionManagerProtocol: Sendable {
    func check(_ type: PermissionType) async -> PermissionStatus
    func check(_ types: [PermissionType]) async -> [PermissionType: PermissionStatus]
    func request(_ type: PermissionType) async -> PermissionStatus
    func request(_ types: [PermissionType]) async -> [PermissionType: PermissionStatus]
    @MainActor func openSettings()
}

public final class PermissionManager: PermissionManagerProtocol, @unchecked Sendable {
    private let handlers: [PermissionType: PermissionHandlerProtocol]

    public init(handlers: [PermissionType: PermissionHandlerProtocol] = [:]) {
        self.handlers = [
            .camera: handlers[.camera] ?? CameraPermissionHandler(),
            .location: handlers[.location] ?? LocationPermissionHandler(),
            .notification: handlers[.notification] ?? NotificationPermissionHandler()
        ]
    }

    public func check(_ type: PermissionType) async -> PermissionStatus {
        guard let handler = handlers[type] else { return .notDetermined }
        return await handler.check()
    }

    public func check(_ types: [PermissionType]) async -> [PermissionType: PermissionStatus] {
        var results: [PermissionType: PermissionStatus] = [:]
        for type in types {
            results[type] = await check(type)
        }
        return results
    }

    public func request(_ type: PermissionType) async -> PermissionStatus {
        guard let handler = handlers[type] else { return .notDetermined }
        return await handler.request()
    }

    public func request(_ types: [PermissionType]) async -> [PermissionType: PermissionStatus] {
        var results: [PermissionType: PermissionStatus] = [:]
        for type in types {
            results[type] = await request(type)
        }
        return results
    }

    @MainActor
    public func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
}
