//
//  CameraStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The camera capability's typed status.
public struct CameraStatus: PermissionStatus, Equatable {
    /// The normalized authorization state.
    public let authorization: PermissionAuthorization

    /// The follow-up action available to the application, if any.
    public let recovery: PermissionRecovery?

    /// Creates a status, typically for tests or previews.
    ///
    /// - Parameters:
    ///   - authorization: The normalized authorization state.
    ///   - recovery: The follow-up action available to the application.
    public init(authorization: PermissionAuthorization, recovery: PermissionRecovery?) {
        self.authorization = authorization
        self.recovery = recovery
    }
}
