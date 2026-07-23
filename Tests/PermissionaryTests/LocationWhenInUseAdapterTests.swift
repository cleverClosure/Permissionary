//
//  LocationWhenInUseAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import CoreLocation
import Testing

@testable import Permissionary

@Suite(.timeLimit(.minutes(1)))
struct LocationWhenInUseAdapterTests {
    private func makeLocation(
        script: LocationScript,
        usageDescription: String? = "Shows nearby places"
    ) -> LocationWhenInUsePermission {
        .adapter(
            shim: script.shim(),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            LocationWhenInUseStatus(native: .notDetermined, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .notDetermined,
                    accuracy: nil,
                    recovery: nil
                )
        )
        #expect(
            LocationWhenInUseStatus(native: .authorizedWhenInUse, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .authorized,
                    accuracy: .full,
                    recovery: nil
                )
        )
        #expect(
            LocationWhenInUseStatus(native: .authorizedAlways, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .authorized,
                    accuracy: .full,
                    recovery: nil
                )
        )
        #expect(
            LocationWhenInUseStatus(native: .denied, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
        #expect(
            LocationWhenInUseStatus(native: .restricted, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(authorization: .restricted, accuracy: nil, recovery: nil)
        )
    }

    @Test("Reduced native accuracy surfaces as reduced precision")
    func reducedAccuracy() {
        #expect(
            LocationWhenInUseStatus(native: .authorizedWhenInUse, nativeAccuracy: .reducedAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .authorized,
                    accuracy: .reduced,
                    recovery: nil
                )
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(CLAuthorizationStatus(rawValue: 99))
        #expect(
            LocationWhenInUseStatus(native: unknown, nativeAccuracy: .fullAccuracy)
                == LocationWhenInUseStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
    }

    @Test("Unknown future accuracy values map to reduced")
    func unknownAccuracy() throws {
        let unknown = try #require(CLAccuracyAuthorization(rawValue: 99))
        #expect(LocationAccuracy(native: unknown) == .reduced)
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = LocationScript(states: [.notDetermined])
        let location = makeLocation(script: script)
        _ = await location.status()
        #expect(script.whenInUseFireCount == 0)
        #expect(script.alwaysFireCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = LocationScript(states: [.notDetermined, .authorizedWhenInUse])
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(
            status
                == LocationWhenInUseStatus(
                    authorization: .authorized,
                    accuracy: .full,
                    recovery: nil
                )
        )
        #expect(script.whenInUseFireCount == 1)
        #expect(script.alwaysFireCount == 0)
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = LocationScript(states: [.notDetermined, .denied])
        let status = try await makeLocation(script: script).request()
        #expect(
            status
                == LocationWhenInUseStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = LocationScript(states: [.denied])
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(status.authorization == .denied)
        #expect(script.whenInUseFireCount == 0)
    }

    @Test("An existing Always grant satisfies the capability without prompting")
    func alwaysAlreadySatisfies() async throws {
        let script = LocationScript(states: [.authorizedAlways])
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(status.authorization == .authorized)
        #expect(script.whenInUseFireCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = LocationScript(states: [.notDetermined])
        let location = makeLocation(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(
                key: "NSLocationWhenInUseUsageDescription"
            )
        ) {
            _ = try await location.request()
        }
        #expect(script.whenInUseFireCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = LocationScript(states: [.authorizedWhenInUse])
        let location = makeLocation(script: script, usageDescription: nil)
        let status = try await location.request()
        #expect(status.authorization == .authorized)
    }

    @Test("Cancellation stops waiting and returns the current status")
    func cancellationStopsWaiting() async throws {
        let script = LocationScript(states: [.notDetermined], emitsChangeOnFire: false)
        let location = makeLocation(script: script)
        let task = Task { try await location.request() }
        task.cancel()
        let status = try await task.value
        #expect(status.authorization == .notDetermined)
    }
}
