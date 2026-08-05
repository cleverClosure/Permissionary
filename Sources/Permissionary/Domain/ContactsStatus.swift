//
//  ContactsStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The contacts capability's typed status.
///
/// ``PermissionAuthorization/limited`` means the user granted access to a
/// selection of contacts rather than the whole database; it is a
/// successful state, and ``PermissionRecovery/manageLimitedSelection``
/// lets the user change the selection.
public struct ContactsStatus: PermissionStatus, Equatable {
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
