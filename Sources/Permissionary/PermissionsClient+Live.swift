//
//  PermissionsClient+Live.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import UIKit

extension PermissionsClient {
    /// A client backed by the real system frameworks.
    public static let live = PermissionsClient(
        openSettings: { await PermissionsClient.openSystemSettings() }
    )

    @MainActor
    private static func openSystemSettings() async {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        _ = await UIApplication.shared.open(url)
    }
}
