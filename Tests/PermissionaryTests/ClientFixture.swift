//
//  ClientFixture.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Foundation

@testable import Permissionary

enum Fixture {
    static func client(
        openSettings: @escaping @Sendable () async -> Void = {}
    ) -> PermissionsClient {
        PermissionsClient(
            camera: CameraPermission(
                status: { CameraStatus(authorization: .notDetermined, recovery: nil) },
                request: { CameraStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            locationWhenInUse: LocationWhenInUsePermission(
                status: {
                    LocationWhenInUseStatus(
                        authorization: .notDetermined,
                        accuracy: nil,
                        recovery: nil
                    )
                },
                request: {
                    LocationWhenInUseStatus(
                        authorization: .notDetermined,
                        accuracy: nil,
                        recovery: nil
                    )
                },
                updates: { AsyncStream { $0.finish() } }
            ),
            locationAlways: LocationAlwaysPermission(
                status: {
                    LocationAlwaysStatus(
                        authorization: .notDetermined,
                        accuracy: nil,
                        recovery: nil
                    )
                },
                request: {
                    LocationAlwaysStatus(
                        authorization: .notDetermined,
                        accuracy: nil,
                        recovery: nil
                    )
                },
                updates: { AsyncStream { $0.finish() } }
            ),
            notifications: NotificationsPermission(
                status: {
                    NotificationsStatus(
                        authorization: .notDetermined,
                        grant: nil,
                        settings: .allDisabled,
                        recovery: nil
                    )
                },
                request: { _ in
                    NotificationsStatus(
                        authorization: .notDetermined,
                        grant: nil,
                        settings: .allDisabled,
                        recovery: nil
                    )
                },
                updates: { AsyncStream { $0.finish() } }
            ),
            photosReadWrite: PhotosReadWritePermission(
                status: { PhotosReadWriteStatus(authorization: .notDetermined, recovery: nil) },
                request: { PhotosReadWriteStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            photosAddOnly: PhotosAddOnlyPermission(
                status: { PhotosAddOnlyStatus(authorization: .notDetermined, recovery: nil) },
                request: { PhotosAddOnlyStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            contacts: ContactsPermission(
                status: { ContactsStatus(authorization: .notDetermined, recovery: nil) },
                request: { ContactsStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            microphone: MicrophonePermission(
                status: { MicrophoneStatus(authorization: .notDetermined, recovery: nil) },
                request: { MicrophoneStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            tracking: TrackingPermission(
                status: { TrackingStatus(authorization: .notDetermined, recovery: nil) },
                request: { TrackingStatus(authorization: .notDetermined, recovery: nil) },
                updates: { AsyncStream { $0.finish() } }
            ),
            openSettings: openSettings
        )
    }
}
