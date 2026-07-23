//
//  MicrophoneStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The microphone capability's typed status.
///
/// The modern audio permission API reports no restricted state, so a
/// device-management restriction surfaces as ``PermissionAuthorization/denied``.
public struct MicrophoneStatus: PermissionStatus, Equatable {
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
