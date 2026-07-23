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
        return PermissionsClient(
            camera: .adapter(shim: .live, infoPlist: .live),
            locationWhenInUse: .adapter(shim: location, infoPlist: .live),
            locationAlways: .adapter(shim: location, infoPlist: .live),
            notifications: .adapter(shim: .live),
            photosReadWrite: .adapter(shim: .live(access: .readWrite), infoPlist: .live),
            photosAddOnly: .adapter(shim: .live(access: .addOnly), infoPlist: .live),
            contacts: .adapter(shim: .live, infoPlist: .live),
            microphone: .adapter(shim: .live, infoPlist: .live),
            tracking: .adapter(shim: .live, infoPlist: .live),
            openSettings: { await PermissionsClient.openSystemSettings() }
        )
    }()

    @MainActor
    private static func openSystemSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        _ = await UIApplication.shared.open(url)
    }
}
