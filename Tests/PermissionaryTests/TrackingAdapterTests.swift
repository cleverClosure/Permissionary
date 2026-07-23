//
//  TrackingAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AppTrackingTransparency
import Testing

@testable import Permissionary

struct TrackingAdapterTests {
    private func makeTracking(
        script: ShimScript<ATTrackingManager.AuthorizationStatus>,
        usageDescription: String? = "Personalizes ads"
    ) -> TrackingPermission {
        .adapter(
            shim: TrackingShim(
                authorizationStatus: { script.nextState() },
                requestAuthorization: { script.recordPrompt() }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            TrackingStatus(native: .notDetermined)
                == TrackingStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            TrackingStatus(native: .authorized)
                == TrackingStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            TrackingStatus(native: .denied)
                == TrackingStatus(authorization: .denied, recovery: .openSettings)
        )
        #expect(
            TrackingStatus(native: .restricted)
                == TrackingStatus(authorization: .restricted, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(ATTrackingManager.AuthorizationStatus(rawValue: 999))
        #expect(
            TrackingStatus(native: unknown)
                == TrackingStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.notDetermined)
        let tracking = makeTracking(script: script)
        _ = await tracking.status()
        #expect(script.promptCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.notDetermined, .authorized)
        let tracking = makeTracking(script: script)
        let status = try await tracking.request()
        #expect(status == TrackingStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.notDetermined, .denied)
        let status = try await makeTracking(script: script).request()
        #expect(status == TrackingStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.denied)
        let tracking = makeTracking(script: script)
        let status = try await tracking.request()
        #expect(status.authorization == .denied)
        #expect(script.promptCount == 0)
    }

    @Test("A restricted system reports restricted without prompting")
    func requestRestricted() async throws {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.restricted)
        let tracking = makeTracking(script: script)
        let status = try await tracking.request()
        #expect(status == TrackingStatus(authorization: .restricted, recovery: nil))
        #expect(script.promptCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.notDetermined)
        let tracking = makeTracking(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(key: "NSUserTrackingUsageDescription")
        ) {
            _ = try await tracking.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<ATTrackingManager.AuthorizationStatus>(.authorized)
        let tracking = makeTracking(script: script, usageDescription: nil)
        let status = try await tracking.request()
        #expect(status.authorization == .authorized)
    }
}
