//
//  PermissionsClientTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionsClientTests {
    @Test("The client runs the injected settings operation")
    func runsInjectedOpenSettings() async {
        await confirmation("openSettings runs") { opened in
            let client = Fixture.client(openSettings: { opened() })
            await client.openSettings()
        }
    }

    @Test("The client runs the injected notification-settings operation")
    func runsInjectedOpenNotificationSettings() async {
        await confirmation("openNotificationSettings runs") { opened in
            let client = Fixture.client(openNotificationSettings: { opened() })
            await client.openNotificationSettings()
        }
    }

    @Test("Capability operations are the injected ones")
    func capabilityInjection() async {
        var client = Fixture.client()
        client.camera = CameraPermission(
            status: { CameraStatus(authorization: .authorized, recovery: nil) },
            request: { CameraStatus(authorization: .authorized, recovery: nil) },
            updates: { AsyncStream { $0.finish() } }
        )
        let status = await client.camera.status()
        #expect(status.authorization == .authorized)
    }

    @Test("A copy with a replaced operation leaves the original untouched")
    func valueSemantics() async {
        let original = Fixture.client()
        var replaced = original
        await confirmation("only the replaced copy runs the new operation") { opened in
            replaced.openSettings = { opened() }
            await replaced.openSettings()
            await original.openSettings()
        }
    }
}
