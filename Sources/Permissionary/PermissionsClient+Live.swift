//
//  PermissionsClient+Live.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import UIKit

extension PermissionsClient {
    /// A client backed by the real system frameworks.
    public static let live: PermissionsClient = {
        let location = LocationShim.live
        let coordination = RequestCoordination()
        let client = PermissionsClient(
            camera: .adapter(shim: .live, infoPlist: .live, coordination: coordination),
            locationWhenInUse: .adapter(
                shim: location,
                infoPlist: .live,
                coordination: coordination
            ),
            locationAlways: .adapter(shim: location, infoPlist: .live, coordination: coordination),
            notifications: .adapter(shim: .live, coordination: coordination),
            photosReadWrite: .adapter(
                shim: .live(access: .readWrite),
                infoPlist: .live,
                coordination: coordination
            ),
            photosAddOnly: .adapter(
                shim: .live(access: .addOnly),
                infoPlist: .live,
                coordination: coordination
            ),
            contacts: .adapter(shim: .live, infoPlist: .live, coordination: coordination),
            microphone: .adapter(shim: .live, infoPlist: .live, coordination: coordination),
            tracking: .adapter(shim: .live, infoPlist: .live, coordination: coordination),
            openSettings: { await PermissionsClient.openSystemSettings() },
            openNotificationSettings: { await PermissionsClient.openSystemNotificationSettings() }
        )
        Task { @MainActor in
            let activations = NotificationCenter.default.notifications(
                named: UIApplication.didBecomeActiveNotification
            )
            for await _ in activations {
                await client.refreshAllStatuses()
            }
        }
        return client
    }()

    @MainActor
    private static func openSystemSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        _ = await UIApplication.shared.open(url)
    }

    @MainActor
    private static func openSystemNotificationSettings() async {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        _ = await UIApplication.shared.open(url)
    }

    func refreshAllStatuses() async {
        _ = await camera.status()
        _ = await locationWhenInUse.status()
        _ = await locationAlways.status()
        _ = await notifications.status()
        _ = await photosReadWrite.status()
        _ = await photosAddOnly.status()
        _ = await contacts.status()
        _ = await microphone.status()
        _ = await tracking.status()
    }
}
