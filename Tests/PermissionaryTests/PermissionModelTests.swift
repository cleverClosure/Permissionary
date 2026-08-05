//
//  PermissionModelTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFoundation
import Synchronization
import Testing

@testable import Permissionary

@MainActor
@Suite(.timeLimit(.minutes(1)))
struct PermissionModelTests {
    @Test("The model loads the initial status without requesting")
    func loadsInitialStatus() async {
        let camera = CameraPermission(
            status: { CameraStatus(authorization: .denied, recovery: .openSettings) },
            request: { CameraStatus(authorization: .denied, recovery: .openSettings) },
            updates: { AsyncStream { $0.finish() } }
        )
        let model = CameraPermissionModel(permission: camera)
        while model.status == nil {
            await Task.yield()
        }
        #expect(model.status == CameraStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("An explicit request publishes its result on the model")
    func requestPublishesResult() async throws {
        let current = Mutex<AVAuthorizationStatus>(.notDetermined)
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { current.withLock { $0 } },
                requestAccess: {
                    current.withLock { $0 = .authorized }
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Takes photos" })
        )
        let model = CameraPermissionModel(permission: camera)
        let result = try await model.request()
        #expect(result.authorization == .authorized)
        #expect(model.status?.authorization == .authorized)
    }

    @Test("Two models of one capability converge through the domain stream")
    func modelsConvergeThroughTheDomainStream() async throws {
        let current = Mutex<AVAuthorizationStatus>(.notDetermined)
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { current.withLock { $0 } },
                requestAccess: {
                    current.withLock { $0 = .authorized }
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Takes photos" })
        )
        let first = CameraPermissionModel(permission: camera)
        let second = CameraPermissionModel(permission: camera)
        while first.status == nil || second.status == nil {
            await Task.yield()
        }

        _ = try await first.request()
        while second.status?.authorization != .authorized {
            await Task.yield()
        }
        #expect(second.status == CameraStatus(authorization: .authorized, recovery: nil))
    }

    @Test("Refresh re-reads the current status")
    func refreshReReads() async {
        let current = Mutex<AVAuthorizationStatus>(.notDetermined)
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { current.withLock { $0 } },
                requestAccess: { true }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Takes photos" })
        )
        let model = CameraPermissionModel(permission: camera)
        while model.status == nil {
            await Task.yield()
        }

        current.withLock { $0 = .denied }
        await model.refresh()
        #expect(model.status == CameraStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("The notifications model requests the standard options by default")
    func notificationsModelDefaultsToStandardOptions() async throws {
        let captured = Mutex<[NotificationOptions]>([])
        let notifications = NotificationsPermission(
            status: {
                NotificationsStatus(
                    authorization: .notDetermined,
                    grant: nil,
                    settings: .allDisabled,
                    recovery: nil
                )
            },
            request: { options in
                captured.withLock { $0.append(options) }
                return NotificationsStatus(
                    authorization: .authorized,
                    grant: .standard,
                    settings: .allDisabled,
                    recovery: nil
                )
            },
            updates: { AsyncStream { $0.finish() } }
        )
        let model = NotificationsPermissionModel(permission: notifications)
        let result = try await model.request()
        #expect(result.grant == .standard)
        #expect(captured.withLock { $0 } == [.standard])
        #expect(model.status?.authorization == .authorized)
    }
}
