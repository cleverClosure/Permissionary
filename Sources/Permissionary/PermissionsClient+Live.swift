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
        return PermissionsClient(
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
            openSettings: { await PermissionsClient.openSystemSettings() }
        )
    }()

    @MainActor
    private static func openSystemSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        _ = await UIApplication.shared.open(url)
    }
}
