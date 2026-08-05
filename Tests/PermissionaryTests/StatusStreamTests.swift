//
//  StatusStreamTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFoundation
import Testing

@testable import Permissionary

@Suite(.timeLimit(.minutes(1)))
struct StatusStreamTests {
    private func makeCamera(
        script: ShimScript<AVAuthorizationStatus>
    ) -> CameraPermission {
        .adapter(
            shim: CameraShim(
                authorizationStatus: { script.nextState() },
                requestAccess: {
                    script.recordPrompt()
                    return true
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in "Takes photos" })
        )
    }

    @Test("A completed request is delivered to update subscribers")
    func requestResultReachesSubscribers() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .authorized)
        let camera = makeCamera(script: script)
        let updates = await camera.updates()
        let reader = Task { await updates.first(where: { _ in true }) }

        _ = try await camera.request()
        let received = await reader.value
        #expect(received == CameraStatus(authorization: .authorized, recovery: nil))
    }

    @Test("Every subscriber of the same capability receives the update")
    func multipleSubscribersReceiveTheUpdate() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .denied)
        let camera = makeCamera(script: script)
        let firstUpdates = await camera.updates()
        let secondUpdates = await camera.updates()
        let firstReader = Task { await firstUpdates.first(where: { _ in true }) }
        let secondReader = Task { await secondUpdates.first(where: { _ in true }) }

        _ = try await camera.request()
        let expected = CameraStatus(authorization: .denied, recovery: .openSettings)
        #expect(await firstReader.value == expected)
        #expect(await secondReader.value == expected)
    }

    @Test("A status read is published to update subscribers")
    func statusReadPublishes() async {
        let script = ShimScript<AVAuthorizationStatus>(.restricted)
        let camera = makeCamera(script: script)
        let updates = await camera.updates()
        let reader = Task { await updates.first(where: { _ in true }) }

        _ = await camera.status()
        let received = await reader.value
        #expect(received == CameraStatus(authorization: .restricted, recovery: nil))
    }
}
