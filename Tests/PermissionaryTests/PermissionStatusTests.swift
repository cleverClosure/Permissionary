//
//  PermissionStatusTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionStatusTests {
    struct StubStatus: PermissionStatus {
        let authorization: PermissionAuthorization
        let recovery: PermissionRecovery?
    }

    @Test("Generic interfaces read any capability's status through the shared protocol")
    func genericAccess() {
        func recoveryAffordance(for status: some PermissionStatus) -> PermissionRecovery? {
            guard status.authorization == .denied || status.authorization == .limited else {
                return nil
            }
            return status.recovery
        }

        let denied = StubStatus(authorization: .denied, recovery: .openSettings)
        let limited = StubStatus(authorization: .limited, recovery: .manageLimitedSelection)
        let restricted = StubStatus(authorization: .restricted, recovery: nil)

        #expect(recoveryAffordance(for: denied) == .openSettings)
        #expect(recoveryAffordance(for: limited) == .manageLimitedSelection)
        #expect(recoveryAffordance(for: restricted) == nil)
    }

    @Test("Statuses cross concurrency boundaries")
    func sendability() async {
        let status = StubStatus(authorization: .authorized, recovery: nil)
        let received = await Task.detached { status }.value
        #expect(received.authorization == .authorized)
        #expect(received.recovery == nil)
    }
}
