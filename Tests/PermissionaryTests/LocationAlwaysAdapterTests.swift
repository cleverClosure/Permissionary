//
//  LocationAlwaysAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import CoreLocation
import Testing

@testable import Permissionary

@Suite(.timeLimit(.minutes(1)))
struct LocationAlwaysAdapterTests {
    private static let bothKeys: @Sendable (String) -> String? = { _ in "Tracks your route" }

    private func makeLocation(
        script: LocationScript,
        infoPlist: @escaping @Sendable (String) -> String? = LocationAlwaysAdapterTests.bothKeys
    ) -> LocationAlwaysPermission {
        .adapter(shim: script.shim(), infoPlist: InfoPlistReader(string: infoPlist))
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            LocationAlwaysStatus(native: .notDetermined, nativeAccuracy: .fullAccuracy)
                == LocationAlwaysStatus(authorization: .notDetermined, accuracy: nil, recovery: nil)
        )
        #expect(
            LocationAlwaysStatus(native: .authorizedWhenInUse, nativeAccuracy: .fullAccuracy)
                == LocationAlwaysStatus(authorization: .limited, accuracy: .full, recovery: nil)
        )
        #expect(
            LocationAlwaysStatus(native: .authorizedAlways, nativeAccuracy: .reducedAccuracy)
                == LocationAlwaysStatus(
                    authorization: .authorized,
                    accuracy: .reduced,
                    recovery: nil
                )
        )
        #expect(
            LocationAlwaysStatus(native: .denied, nativeAccuracy: .fullAccuracy)
                == LocationAlwaysStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
        #expect(
            LocationAlwaysStatus(native: .restricted, nativeAccuracy: .fullAccuracy)
                == LocationAlwaysStatus(authorization: .restricted, accuracy: nil, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(CLAuthorizationStatus(rawValue: 99))
        #expect(
            LocationAlwaysStatus(native: unknown, nativeAccuracy: .fullAccuracy)
                == LocationAlwaysStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = LocationScript(states: [.authorizedWhenInUse])
        let location = makeLocation(script: script)
        _ = await location.status()
        #expect(script.whenInUseFireCount == 0)
        #expect(script.alwaysFireCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = LocationScript(states: [.notDetermined, .authorizedAlways])
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(
            status
                == LocationAlwaysStatus(authorization: .authorized, accuracy: .full, recovery: nil)
        )
        #expect(script.alwaysFireCount == 1)
        #expect(script.whenInUseFireCount == 0)
    }

    @Test("A when-in-use answer to the first prompt is reported as limited")
    func requestAnsweredWithWhenInUse() async throws {
        let script = LocationScript(states: [.notDetermined, .authorizedWhenInUse])
        let status = try await makeLocation(script: script).request()
        #expect(
            status == LocationAlwaysStatus(authorization: .limited, accuracy: .full, recovery: nil)
        )
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = LocationScript(states: [.notDetermined, .denied])
        let status = try await makeLocation(script: script).request()
        #expect(
            status
                == LocationAlwaysStatus(
                    authorization: .denied,
                    accuracy: nil,
                    recovery: .openSettings
                )
        )
    }

    @Test("The upgrade from when-in-use fires once and returns without waiting")
    func upgradeFiresAndReturnsCurrentSnapshot() async throws {
        let script = LocationScript(states: [.authorizedWhenInUse], emitsChangeOnFire: false)
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(
            status == LocationAlwaysStatus(authorization: .limited, accuracy: .full, recovery: nil)
        )
        #expect(script.alwaysFireCount == 1)
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = LocationScript(states: [.denied])
        let location = makeLocation(script: script)
        let status = try await location.request()
        #expect(status.authorization == .denied)
        #expect(script.alwaysFireCount == 0)
    }

    @Test("A missing always usage description fails and names the always key")
    func missingAlwaysKey() async {
        let script = LocationScript(states: [.notDetermined])
        let location = makeLocation(
            script: script,
            infoPlist: { key in
                key == "NSLocationWhenInUseUsageDescription" ? "Shows nearby places" : nil
            }
        )
        await #expect(
            throws: PermissionError.missingUsageDescription(
                key: "NSLocationAlwaysAndWhenInUseUsageDescription"
            )
        ) {
            _ = try await location.request()
        }
        #expect(script.alwaysFireCount == 0)
    }

    @Test("A missing when-in-use usage description is reported first")
    func missingWhenInUseKey() async {
        let script = LocationScript(states: [.notDetermined])
        let location = makeLocation(script: script, infoPlist: { _ in nil })
        await #expect(
            throws: PermissionError.missingUsageDescription(
                key: "NSLocationWhenInUseUsageDescription"
            )
        ) {
            _ = try await location.request()
        }
    }

    @Test("The upgrade validates configuration before firing")
    func upgradeValidatesKeys() async {
        let script = LocationScript(states: [.authorizedWhenInUse])
        let location = makeLocation(
            script: script,
            infoPlist: { key in
                key == "NSLocationWhenInUseUsageDescription" ? "Shows nearby places" : nil
            }
        )
        await #expect(
            throws: PermissionError.missingUsageDescription(
                key: "NSLocationAlwaysAndWhenInUseUsageDescription"
            )
        ) {
            _ = try await location.request()
        }
        #expect(script.alwaysFireCount == 0)
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
