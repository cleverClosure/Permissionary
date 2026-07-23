//
//  PermissionsClientTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Testing

@testable import Permissionary

struct PermissionsClientTests {
    @Test("The client runs the injected settings operation")
    func runsInjectedOpenSettings() async {
        await confirmation("openSettings runs") { opened in
            let client = PermissionsClient(openSettings: { opened() })
            await client.openSettings()
        }
    }

    @Test("A copy with a replaced operation leaves the original untouched")
    func valueSemantics() async {
        let original = PermissionsClient(openSettings: {})
        var replaced = original
        await confirmation("only the replaced copy runs the new operation") { opened in
            replaced.openSettings = { opened() }
            await replaced.openSettings()
            await original.openSettings()
        }
    }
}
