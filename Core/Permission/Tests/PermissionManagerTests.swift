import XCTest
import UIKit
import AVFoundation
import CoreLocation
import UserNotifications
import FactoryKit
@testable import CorePermission

final class MockPermissionHandler: PermissionHandlerProtocol, @unchecked Sendable {
    var checkResult: PermissionStatus
    var requestResult: PermissionStatus
    var checkCallCount = 0
    var requestCallCount = 0

    init(checkResult: PermissionStatus = .notDetermined, requestResult: PermissionStatus = .granted) {
        self.checkResult = checkResult
        self.requestResult = requestResult
    }

    func check() async -> PermissionStatus {
        checkCallCount += 1
        return checkResult
    }

    func request() async -> PermissionStatus {
        requestCallCount += 1
        return requestResult
    }
}

final class PermissionManagerTests: XCTestCase {
    private var mockCamera: MockPermissionHandler!
    private var mockLocation: MockPermissionHandler!
    private var mockNotification: MockPermissionHandler!
    private var sut: PermissionManager!

    override func setUp() {
        super.setUp()
        mockCamera = MockPermissionHandler(checkResult: .granted, requestResult: .granted)
        mockLocation = MockPermissionHandler(checkResult: .denied, requestResult: .granted)
        mockNotification = MockPermissionHandler(checkResult: .notDetermined, requestResult: .granted)

        sut = PermissionManager(handlers: [
            .camera: mockCamera,
            .location: mockLocation,
            .notification: mockNotification
        ])
    }

    override func tearDown() {
        mockCamera = nil
        mockLocation = nil
        mockNotification = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - PermissionManager Tests

    func test_defaultInitialization() async {
        let defaultManager = PermissionManager()
        let cameraStatus = await defaultManager.check(.camera)
        let locationStatus = await defaultManager.check(.location)
        let notificationStatus = await defaultManager.check(.notification)

        XCTAssertNotNil(cameraStatus)
        XCTAssertNotNil(locationStatus)
        XCTAssertNotNil(notificationStatus)
    }

    func test_checkSinglePermission() async {
        let cameraStatus = await sut.check(.camera)
        let locationStatus = await sut.check(.location)

        XCTAssertEqual(cameraStatus, .granted)
        XCTAssertEqual(locationStatus, .denied)
        XCTAssertEqual(mockCamera.checkCallCount, 1)
        XCTAssertEqual(mockLocation.checkCallCount, 1)
    }

    func test_requestSinglePermission() async {
        let cameraStatus = await sut.request(.camera)
        let locationStatus = await sut.request(.location)

        XCTAssertEqual(cameraStatus, .granted)
        XCTAssertEqual(locationStatus, .granted)
        XCTAssertEqual(mockCamera.requestCallCount, 1)
        XCTAssertEqual(mockLocation.requestCallCount, 1)
    }

    func test_checkBatchPermissions() async {
        let result = await sut.check([.camera, .location, .notification])

        XCTAssertEqual(result[.camera], .granted)
        XCTAssertEqual(result[.location], .denied)
        XCTAssertEqual(result[.notification], .notDetermined)

        XCTAssertFalse(result.allGranted)
        XCTAssertTrue(result.anyDenied)
        XCTAssertTrue(result.isGranted(.camera))
        XCTAssertFalse(result.isGranted(.location))
    }

    func test_requestBatchPermissions() async {
        let result = await sut.request([.camera, .location, .notification])

        XCTAssertEqual(result[.camera], .granted)
        XCTAssertEqual(result[.location], .granted)
        XCTAssertEqual(result[.notification], .granted)

        XCTAssertTrue(result.allGranted)
        XCTAssertFalse(result.anyDenied)
        XCTAssertEqual(mockCamera.requestCallCount, 1)
        XCTAssertEqual(mockLocation.requestCallCount, 1)
        XCTAssertEqual(mockNotification.requestCallCount, 1)
    }

    @MainActor
    func test_openSettings() {
        sut.openSettings()
        // Method should execute without crashing
        XCTAssertTrue(true)
    }

    func test_permissionResult_helpers() {
        let allGrantedResult: PermissionResult = [
            .camera: .granted,
            .location: .granted
        ]
        XCTAssertTrue(allGrantedResult.allGranted)
        XCTAssertFalse(allGrantedResult.anyDenied)

        let mixedResult: PermissionResult = [
            .camera: .granted,
            .location: .denied
        ]
        XCTAssertFalse(mixedResult.allGranted)
        XCTAssertTrue(mixedResult.anyDenied)

        let emptyResult: PermissionResult = [:]
        XCTAssertFalse(emptyResult.allGranted)
        XCTAssertFalse(emptyResult.anyDenied)
    }

    func test_containerRegistration() {
        let permissionService = Container.shared.permission()
        XCTAssertNotNil(permissionService)
    }

    func test_permissionType_localizedStrings() {
        for type in PermissionType.allCases {
            XCTAssertFalse(type.title.isEmpty)
            XCTAssertFalse(type.description.isEmpty)
        }
    }

    // MARK: - CameraPermissionHandler Tests

    func test_cameraPermissionHandler() async {
        let handler = CameraPermissionHandler()
        let status = await handler.check()
        XCTAssertTrue([.granted, .denied, .restricted, .notDetermined].contains(status))

        let requestStatus = await handler.request()
        XCTAssertTrue([.granted, .denied, .restricted, .notDetermined].contains(requestStatus))
    }

    // MARK: - LocationPermissionHandler Tests

    @MainActor
    func test_locationPermissionHandler() async {
        let handler = LocationPermissionHandler()
        let status = await handler.check()
        XCTAssertTrue([.granted, .denied, .restricted, .notDetermined].contains(status))

        // Reuse helper caching check
        let secondStatus = await handler.check()
        XCTAssertEqual(status, secondStatus)

        // Helper directly
        let helper = LocationDelegateHelper()
        let helperStatus = helper.checkStatus()
        XCTAssertTrue([.granted, .denied, .restricted, .notDetermined].contains(helperStatus))

        // Trigger delegate when continuation is nil
        helper.locationManagerDidChangeAuthorization(CLLocationManager())

        // If status is not undetermined, request returns current status
        if status != .notDetermined {
            let req = await handler.request()
            XCTAssertEqual(req, status)
        }

        // Test with customStatus for LocationPermissionHandler & LocationDelegateHelper
        let authorizedHandler = LocationPermissionHandler(customStatus: .authorizedWhenInUse)
        let authStatus = await authorizedHandler.check()
        XCTAssertEqual(authStatus, .granted)
        let authReq = await authorizedHandler.request()
        XCTAssertEqual(authReq, .granted)

        let alwaysHandler = LocationPermissionHandler(customStatus: .authorizedAlways)
        let alwaysStatus = await alwaysHandler.check()
        XCTAssertEqual(alwaysStatus, .granted)

        let deniedHandler = LocationPermissionHandler(customStatus: .denied)
        let deniedStatus = await deniedHandler.check()
        let deniedReq = await deniedHandler.request()
        XCTAssertEqual(deniedStatus, .denied)
        XCTAssertEqual(deniedReq, .denied)

        let restrictedHandler = LocationPermissionHandler(customStatus: .restricted)
        let restrictedStatus = await restrictedHandler.check()
        let restrictedReq = await restrictedHandler.request()
        XCTAssertEqual(restrictedStatus, .restricted)
        XCTAssertEqual(restrictedReq, .restricted)

        let notDeterminedHelper = LocationDelegateHelper(customStatus: .notDetermined)
        let notDeterminedStatus = notDeterminedHelper.checkStatus()
        XCTAssertEqual(notDeterminedStatus, .notDetermined)
    }

    // MARK: - NotificationPermissionHandler Tests

    func test_notificationPermissionHandler_defaultInit() async {
        let handler = NotificationPermissionHandler()
        let status = await handler.check()
        XCTAssertEqual(status, .notDetermined)

        let requestStatus = await handler.request()
        XCTAssertEqual(requestStatus, .notDetermined)

        let handlerNilCenter = NotificationPermissionHandler(center: nil)
        let statusNil = await handlerNilCenter.check()
        XCTAssertEqual(statusNil, .notDetermined)
    }

    func test_notificationPermissionHandler_statusAndRequestProviders() async {
        // 1. Authorized
        let authorizedHandler = NotificationPermissionHandler(statusProvider: { .authorized })
        let authStatus = await authorizedHandler.check()
        let authReq = await authorizedHandler.request()
        XCTAssertEqual(authStatus, .granted)
        XCTAssertEqual(authReq, .granted)

        // 2. Provisional
        let provisionalHandler = NotificationPermissionHandler(statusProvider: { .provisional })
        let provStatus = await provisionalHandler.check()
        XCTAssertEqual(provStatus, .granted)

        // 3. Ephemeral
        let ephemeralHandler = NotificationPermissionHandler(statusProvider: { .ephemeral })
        let ephStatus = await ephemeralHandler.check()
        XCTAssertEqual(ephStatus, .granted)

        // 4. Denied
        let deniedHandler = NotificationPermissionHandler(statusProvider: { .denied })
        let denStatus = await deniedHandler.check()
        let denReq = await deniedHandler.request()
        XCTAssertEqual(denStatus, .denied)
        XCTAssertEqual(denReq, .denied)

        // 5. Not determined -> request succeeds
        let requestSuccessHandler = NotificationPermissionHandler(
            statusProvider: { .notDetermined },
            requestProvider: { true }
        )
        let reqSuccessCheck = await requestSuccessHandler.check()
        let reqSuccessResult = await requestSuccessHandler.request()
        XCTAssertEqual(reqSuccessCheck, .notDetermined)
        XCTAssertEqual(reqSuccessResult, .granted)

        // 6. Not determined -> request denied
        let requestDeniedHandler = NotificationPermissionHandler(
            statusProvider: { .notDetermined },
            requestProvider: { false }
        )
        let reqDeniedResult = await requestDeniedHandler.request()
        XCTAssertEqual(reqDeniedResult, .denied)

        // 7. Not determined -> request throws error
        let requestErrorHandler = NotificationPermissionHandler(
            statusProvider: { .notDetermined },
            requestProvider: { throw NSError(domain: "test", code: 1) }
        )
        let reqErrorResult = await requestErrorHandler.request()
        XCTAssertEqual(reqErrorResult, .denied)
    }
}
