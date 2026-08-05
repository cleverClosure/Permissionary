//
//  READMEExamples.swift
//  PermissionaryTests
//
//  Created by Timur Isaev
//

import Permissionary
import SwiftUI

// Compile-only mirrors of the code examples in README.md, kept aligned with
// the documentation. The release gate requires these examples to compile;
// when the public API drifts, this file breaks the build. Nothing here runs.

func auditPermissionConfiguration() {
    for issue in PermissionsDiagnostics.configurationIssues() {
        print(issue)
    }
}

func enableCamera(permissions: PermissionsClient = .live) async throws {
    let status = try await permissions.camera.request()

    if status.authorization == .authorized {
        print("Camera is ready")
    }
}

struct CameraStatusView: View {
    private let permissions: PermissionsClient
    @State private var model: CameraPermissionModel

    init(permissions: PermissionsClient = .live) {
        self.permissions = permissions
        _model = State(
            initialValue: CameraPermissionModel(permission: permissions.camera)
        )
    }

    var body: some View {
        VStack {
            Text(model.status.map { String(describing: $0.authorization) } ?? "Loading")

            Button("Enable Camera") {
                Task {
                    _ = try? await model.request()
                }
            }

            if model.status?.recovery == .openSettings {
                Button("Open Settings") {
                    Task {
                        await permissions.openSettings()
                    }
                }
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
