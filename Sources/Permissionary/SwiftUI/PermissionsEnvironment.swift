//
//  PermissionsEnvironment.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import SwiftUI

extension EnvironmentValues {
    /// The permissions client available to views.
    ///
    /// Defaults to the live client, which is safe because status reads
    /// never present a prompt. Previews and tests should inject
    /// deterministic fakes.
    @Entry public var permissions: PermissionsClient = .live
}
