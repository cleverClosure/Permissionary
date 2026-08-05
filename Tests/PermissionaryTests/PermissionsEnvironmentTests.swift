//
//  PermissionsEnvironmentTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import SwiftUI
import Testing

@testable import Permissionary

struct PermissionsEnvironmentTests {
    @Test("An injected client replaces the environment value")
    func environmentOverrideInjects() async {
        await confirmation("the injected client's operation runs") { opened in
            var values = EnvironmentValues()
            values.permissions = Fixture.client(openSettings: { opened() })
            await values.permissions.openSettings()
        }
    }
}
