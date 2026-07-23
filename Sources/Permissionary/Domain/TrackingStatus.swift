//
//  TrackingStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The app-tracking-transparency capability's typed status.
///
/// ``PermissionAuthorization/restricted`` includes the system-wide
/// "Allow Apps to Request to Track" switch being off; Settings recovery
/// is not offered for it because the per-app toggle may not exist.
public struct TrackingStatus: PermissionStatus, Equatable {
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
