//
//  PermissionAuthorizationTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionAuthorizationTests {
    @Test("Authorization values are equatable")
    func equality() {
        #expect(PermissionAuthorization.authorized == .authorized)
        #expect(PermissionAuthorization.denied != .restricted)
    }

    @Test("Authorization values cross concurrency boundaries")
    func sendability() async {
        let authorization = PermissionAuthorization.limited
        let received = await Task.detached { authorization }.value
        #expect(received == .limited)
    }
}
