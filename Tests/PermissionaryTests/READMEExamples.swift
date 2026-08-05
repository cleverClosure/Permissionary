//
//  READMEExamples.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

// Compile-only mirrors of the code examples in README.md, kept byte-identical.
// The release gate requires README examples to compile; when the public API
// drifts from the documentation, this file breaks the build. Nothing here runs.

func auditPermissionConfiguration() {
    for issue in PermissionsDiagnostics.configurationIssues() {
        print(issue)
    }
}

func enableCamera(permissions: PermissionsClient) async throws {
    let status = await permissions.camera.status()
    guard status.authorization == .notDetermined else {
        return
    }

    let result = try await permissions.camera.request()
    if result.recovery == .openSettings {
        await permissions.openSettings()
    }
}

struct CameraStatusView: View {
    @Environment(\.permissions) private var permissions
    @State private var model: CameraPermissionModel?

    var body: some View {
        VStack {
            Text(model?.status.map { String(describing: $0.authorization) } ?? "loading")
            Button("Enable Camera") {
                Task {
                    _ = try? await model?.request()
                }
            }
        }
        .task {
            if model == nil {
                model = CameraPermissionModel(permission: permissions.camera)
            }
        }
    }
}

func observeCamera(permissions: PermissionsClient) async {
    for await status in await permissions.camera.updates() {
        print(status.authorization)
    }
}

func requestQuietNotifications(permissions: PermissionsClient) async throws {
    let result = try await permissions.notifications.request([.alert, .sound, .provisional])
    if result.grant == .provisional {
        print("Delivering quietly until the user promotes them.")
    }
}

func makeStubClient() -> PermissionsClient {
    var permissions = PermissionsClient.live
    permissions.camera = CameraPermission(
        status: { CameraStatus(authorization: .authorized, recovery: nil) },
        request: { CameraStatus(authorization: .authorized, recovery: nil) },
        updates: { AsyncStream { $0.finish() } }
    )
    return permissions
}
