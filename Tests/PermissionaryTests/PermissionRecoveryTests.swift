//
//  PermissionRecoveryTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionRecoveryTests {
    @Test("Recovery values are equatable")
    func equality() {
        #expect(PermissionRecovery.openSettings == .openSettings)
        #expect(PermissionRecovery.openSettings != .manageLimitedSelection)
    }

    @Test("Recovery values cross concurrency boundaries")
    func sendability() async {
        let recovery = PermissionRecovery.manageLimitedSelection
        let received = await Task.detached { recovery }.value
        #expect(received == .manageLimitedSelection)
    }
}
