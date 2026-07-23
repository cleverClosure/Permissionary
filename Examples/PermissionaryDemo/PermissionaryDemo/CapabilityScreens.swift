//
//  CapabilityScreens.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import ContactsUI
import Permissionary
import SwiftUI

@MainActor
struct CameraScreen: View {
    let model: CameraPermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Camera",
            usageKeys: ["NSCameraUsageDescription"],
            status: model.status,
            request: { try await model.request() },
            refresh: { await model.refresh() }
        )
    }
}

@MainActor
struct MicrophoneScreen: View {
    let model: MicrophonePermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Microphone",
            usageKeys: ["NSMicrophoneUsageDescription"],
            status: model.status,
            request: { try await model.request() },
            refresh: { await model.refresh() }
        )
    }
}

@MainActor
struct PhotosReadWriteScreen: View {
    let model: PhotosReadWritePermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Photos Read/Write",
            usageKeys: ["NSPhotoLibraryUsageDescription"],
            status: model.status,
            note: "Limited access is a successful state with its own recovery action.",
            request: { try await model.request() },
            refresh: { await model.refresh() },
            manageLimitedSelection: { LimitedLibraryPicker.present() }
        )
    }
}

@MainActor
struct PhotosAddOnlyScreen: View {
    let model: PhotosAddOnlyPermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Photos Add Only",
            usageKeys: ["NSPhotoLibraryAddUsageDescription"],
            status: model.status,
            note: "Add-only access is independent of read/write access.",
            request: { try await model.request() },
            refresh: { await model.refresh() }
        )
    }
}

@MainActor
struct ContactsScreen: View {
    let model: ContactsPermissionModel

    @State private var isManagingSelection = false

    var body: some View {
        CapabilityScreen(
            title: "Contacts",
            usageKeys: ["NSContactsUsageDescription"],
            status: model.status,
            note: "Limited access shares only the contacts the user selected.",
            request: { try await model.request() },
            refresh: { await model.refresh() },
            manageLimitedSelection: { isManagingSelection = true }
        )
        .contactAccessPicker(isPresented: $isManagingSelection) { _ in
        }
    }
}

@MainActor
struct LocationWhenInUseScreen: View {
    let model: LocationWhenInUsePermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Location When In Use",
            usageKeys: ["NSLocationWhenInUseUsageDescription"],
            status: model.status,
            note: "An Always grant satisfies this capability and reports as authorized.",
            request: { try await model.request() },
            refresh: { await model.refresh() },
            details: { status in
                LabeledContent("Accuracy", value: accuracyLabel(status.accuracy))
            }
        )
    }
}

@MainActor
struct LocationAlwaysScreen: View {
    let model: LocationAlwaysPermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Location Always",
            usageKeys: [
                "NSLocationWhenInUseUsageDescription",
                "NSLocationAlwaysAndWhenInUseUsageDescription",
            ],
            status: model.status,
            note: "A when-in-use grant reports as limited. The system shows the upgrade "
                + "prompt at most once per install and may defer it; the request never hangs.",
            request: { try await model.request() },
            refresh: { await model.refresh() },
            details: { status in
                LabeledContent("Accuracy", value: accuracyLabel(status.accuracy))
            }
        )
    }
}

@MainActor
struct TrackingScreen: View {
    let model: TrackingPermissionModel

    var body: some View {
        CapabilityScreen(
            title: "Tracking",
            usageKeys: ["NSUserTrackingUsageDescription"],
            status: model.status,
            note: "The prompt requires an active application and the system-wide "
                + "Allow Apps to Request to Track switch.",
            request: { try await model.request() },
            refresh: { await model.refresh() }
        )
    }
}

private func accuracyLabel(_ accuracy: LocationAccuracy?) -> String {
    guard let accuracy else {
        return "none"
    }
    return String(describing: accuracy)
}
