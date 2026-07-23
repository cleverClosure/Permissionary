//
//  CameraAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFoundation
import Testing

@testable import Permissionary

struct CameraAdapterTests {
    private func makeCamera(
        script: ShimScript<AVAuthorizationStatus>,
        grants: Bool = true,
        usageDescription: String? = "Takes photos"
    ) -> CameraPermission {
        .adapter(
            shim: CameraShim(
                authorizationStatus: { script.nextState() },
                requestAccess: {
                    script.recordPrompt()
                    return grants
                }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            CameraStatus(native: .notDetermined)
                == CameraStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            CameraStatus(native: .authorized)
                == CameraStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            CameraStatus(native: .denied)
                == CameraStatus(authorization: .denied, recovery: .openSettings)
        )
        #expect(
            CameraStatus(native: .restricted)
                == CameraStatus(authorization: .restricted, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(AVAuthorizationStatus(rawValue: 999))
        #expect(
            CameraStatus(native: unknown)
                == CameraStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined)
        let camera = makeCamera(script: script)
        _ = await camera.status()
        #expect(script.promptCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .authorized)
        let camera = makeCamera(script: script)
        let status = try await camera.request()
        #expect(status == CameraStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .denied)
        let status = try await makeCamera(script: script, grants: false).request()
        #expect(status == CameraStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.denied)
        let camera = makeCamera(script: script)
        let status = try await camera.request()
        #expect(status.authorization == .denied)
        #expect(script.promptCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined)
        let camera = makeCamera(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(key: "NSCameraUsageDescription")
        ) {
            _ = try await camera.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.authorized)
        let camera = makeCamera(script: script, usageDescription: nil)
        let status = try await camera.request()
        #expect(status.authorization == .authorized)
    }

    @Test("The status after the prompt is re-read, not assumed from the grant")
    func finalStateIsReRead() async throws {
        let script = ShimScript<AVAuthorizationStatus>(.notDetermined, .restricted)
        let status = try await makeCamera(script: script, grants: true).request()
        #expect(status.authorization == .restricted)
    }
}
