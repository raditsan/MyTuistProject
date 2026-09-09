import XCTest
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

    func test_checkSinglePermission() async {
        let cameraStatus = await sut.check(.camera)
        let locationStatus = await sut.check(.location)

        XCTAssertEqual(cameraStatus, .granted)
        XCTAssertEqual(locationStatus, .denied)
        XCTAssertEqual(mockCamera.checkCallCount, 1)
        XCTAssertEqual(mockLocation.checkCallCount, 1)
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
        XCTAssertFalse(PermissionType.camera.title.isEmpty)
        XCTAssertFalse(PermissionType.camera.description.isEmpty)
        XCTAssertFalse(PermissionType.location.title.isEmpty)
        XCTAssertFalse(PermissionType.location.description.isEmpty)
        XCTAssertFalse(PermissionType.notification.title.isEmpty)
        XCTAssertFalse(PermissionType.notification.description.isEmpty)
    }
}
