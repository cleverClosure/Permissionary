//
//  CapabilityListView.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

@MainActor
struct CapabilityListView: View {
    @Environment(\.permissions) private var permissions
    @State private var models: DemoModels?

    var body: some View {
        NavigationStack {
            Group {
                if let models {
                    capabilityList(models)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Permissionary")
        }
        .task {
            if models == nil {
                models = DemoModels(client: permissions)
            }
        }
    }

    private func capabilityList(_ models: DemoModels) -> some View {
        List {
            Section("Capabilities") {
                row("Camera", authorization: models.camera.status?.authorization) {
                    CameraScreen(model: models.camera)
                }
                row("Microphone", authorization: models.microphone.status?.authorization) {
                    MicrophoneScreen(model: models.microphone)
                }
                row(
                    "Photos Read/Write",
                    authorization: models.photosReadWrite.status?.authorization
                ) {
                    PhotosReadWriteScreen(model: models.photosReadWrite)
                }
                row("Photos Add Only", authorization: models.photosAddOnly.status?.authorization) {
                    PhotosAddOnlyScreen(model: models.photosAddOnly)
                }
                row("Contacts", authorization: models.contacts.status?.authorization) {
                    ContactsScreen(model: models.contacts)
                }
                row(
                    "Location When In Use",
                    authorization: models.locationWhenInUse.status?.authorization
                ) {
                    LocationWhenInUseScreen(model: models.locationWhenInUse)
                }
                row(
                    "Location Always",
                    authorization: models.locationAlways.status?.authorization
                ) {
                    LocationAlwaysScreen(model: models.locationAlways)
                }
                row("Notifications", authorization: models.notifications.status?.authorization) {
                    NotificationsScreen(model: models.notifications)
                }
                row("Tracking", authorization: models.tracking.status?.authorization) {
                    TrackingScreen(model: models.tracking)
                }
            }
            Section("Lab") {
                NavigationLink("Coordination") {
                    CoordinationLabScreen()
                }
            }
        }
    }

    private func row<Destination: View>(
        _ title: String,
        authorization: PermissionAuthorization?,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            LabeledContent(title) {
                AuthorizationBadge(authorization: authorization)
            }
        }
    }
}
