//
//  PermissionsClientTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

private enum Fixture {
    static func client(
        openSettings: @escaping @Sendable () async -> Void = {}
    ) -> PermissionsClient {
        PermissionsClient(
            camera: CameraPermission(
                status: { CameraStatus(authorization: .notDetermined, recovery: nil) },
                request: { CameraStatus(authorization: .notDetermined, recovery: nil) }
            ),
            photosReadWrite: PhotosReadWritePermission(
                status: { PhotosReadWriteStatus(authorization: .notDetermined, recovery: nil) },
                request: { PhotosReadWriteStatus(authorization: .notDetermined, recovery: nil) }
            ),
            photosAddOnly: PhotosAddOnlyPermission(
                status: { PhotosAddOnlyStatus(authorization: .notDetermined, recovery: nil) },
                request: { PhotosAddOnlyStatus(authorization: .notDetermined, recovery: nil) }
            ),
            contacts: ContactsPermission(
                status: { ContactsStatus(authorization: .notDetermined, recovery: nil) },
                request: { ContactsStatus(authorization: .notDetermined, recovery: nil) }
            ),
            microphone: MicrophonePermission(
                status: { MicrophoneStatus(authorization: .notDetermined, recovery: nil) },
                request: { MicrophoneStatus(authorization: .notDetermined, recovery: nil) }
            ),
            tracking: TrackingPermission(
                status: { TrackingStatus(authorization: .notDetermined, recovery: nil) },
                request: { TrackingStatus(authorization: .notDetermined, recovery: nil) }
            ),
            openSettings: openSettings
        )
    }
}

struct PermissionsClientTests {
    @Test("The client runs the injected settings operation")
    func runsInjectedOpenSettings() async {
        await confirmation("openSettings runs") { opened in
            let client = Fixture.client(openSettings: { opened() })
            await client.openSettings()
        }
    }

    @Test("Capability operations are the injected ones")
    func capabilityInjection() async {
        var client = Fixture.client()
        client.camera = CameraPermission(
            status: { CameraStatus(authorization: .authorized, recovery: nil) },
            request: { CameraStatus(authorization: .authorized, recovery: nil) }
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
