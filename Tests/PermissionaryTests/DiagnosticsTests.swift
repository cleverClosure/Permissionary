//
//  DiagnosticsTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import AVFoundation
import Testing

@testable import Permissionary

struct DiagnosticsTests {
    @Test("A complete configuration reports no issues")
    func completeConfiguration() {
        let issues = PermissionsDiagnostics.configurationIssues(
            infoPlist: InfoPlistReader(string: { _ in "Explains usage" })
        )
        #expect(issues.isEmpty)
    }

    @Test("A missing key is reported as the error its request would throw")
    func missingKey() {
        let issues = PermissionsDiagnostics.configurationIssues(
            infoPlist: InfoPlistReader(string: { key in
                key == UsageDescriptionKey.camera ? nil : "Explains usage"
            })
        )
        #expect(issues == [.missingUsageDescription(key: UsageDescriptionKey.camera)])
    }

    @Test("An empty usage description is an issue")
    func emptyDescription() {
        let issues = PermissionsDiagnostics.configurationIssues(
            infoPlist: InfoPlistReader(string: { key in
                key == UsageDescriptionKey.tracking ? "" : "Explains usage"
            })
        )
        #expect(issues == [.missingUsageDescription(key: UsageDescriptionKey.tracking)])
    }

    @Test("An unconfigured application reports every required key exactly once")
    func unconfiguredApplication() {
        let issues = PermissionsDiagnostics.configurationIssues(
            infoPlist: InfoPlistReader(string: { _ in nil })
        )
        let keys = issues.compactMap { issue -> String? in
            guard case .missingUsageDescription(let key) = issue else {
                return nil
            }
            return key
        }
        let expected: Set = [
            UsageDescriptionKey.camera,
            UsageDescriptionKey.microphone,
            UsageDescriptionKey.photoLibrary,
            UsageDescriptionKey.photoLibraryAdd,
            UsageDescriptionKey.contacts,
            UsageDescriptionKey.locationWhenInUse,
            UsageDescriptionKey.locationAlwaysAndWhenInUse,
            UsageDescriptionKey.tracking,
        ]
        #expect(keys.count == expected.count)
        #expect(Set(keys) == expected)
    }

    @Test("Diagnostics reports the same error a request throws")
    func matchesRequestError() async {
        let infoPlist = InfoPlistReader(string: { _ in nil })
        let camera = CameraPermission.adapter(
            shim: CameraShim(
                authorizationStatus: { .notDetermined },
                requestAccess: { true }
            ),
            infoPlist: infoPlist
        )
        do {
            _ = try await camera.request()
            Issue.record("The request should throw for a missing usage description")
        } catch let error as PermissionError {
            let issues = PermissionsDiagnostics.configurationIssues(infoPlist: infoPlist)
            #expect(issues.contains(error))
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
