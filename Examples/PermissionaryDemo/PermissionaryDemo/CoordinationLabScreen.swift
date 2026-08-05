//
//  CoordinationLabScreen.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

@MainActor
struct CoordinationLabScreen: View {
    @Environment(\.permissions) private var permissions

    @State private var isRunning = false
    @State private var outcome = ""

    var body: some View {
        Form {
            Section {
                Button("Request camera twice") {
                    requestCameraTwice()
                }
                .disabled(isRunning)
            } footer: {
                Text(
                    "Both callers coalesce into one native request: a single prompt, "
                        + "and both receive the same final status."
                )
            }
            Section {
                Button("Request camera and microphone") {
                    requestCameraAndMicrophone()
                }
                .disabled(isRunning)
            } footer: {
                Text(
                    "Prompts are serialized: the microphone prompt appears only after "
                        + "the camera prompt is answered, never stacked."
                )
            }
            if !outcome.isEmpty {
                Section("Outcome") {
                    Text(outcome)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Coordination")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func requestCameraTwice() {
        run { camera, _ in
            async let first = camera.request()
            async let second = camera.request()
            let statuses = try await (first, second)
            return "first: \(statuses.0.authorization), second: \(statuses.1.authorization)"
        }
    }

    private func requestCameraAndMicrophone() {
        run { camera, microphone in
            async let cameraStatus = camera.request()
            async let microphoneStatus = microphone.request()
            let statuses = try await (cameraStatus, microphoneStatus)
            return "camera: \(statuses.0.authorization), microphone: \(statuses.1.authorization)"
        }
    }

    private func run(
        _ operation: @escaping (CameraPermission, MicrophonePermission) async throws -> String
    ) {
        isRunning = true
        outcome = ""
        Task {
            do {
                outcome = try await operation(permissions.camera, permissions.microphone)
            } catch {
                outcome = String(describing: error)
            }
            isRunning = false
        }
    }
}
