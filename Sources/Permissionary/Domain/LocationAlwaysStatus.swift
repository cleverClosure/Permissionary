//
//  LocationAlwaysStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The always location capability's typed status.
///
/// A when-in-use grant is reported as
/// ``PermissionAuthorization/limited``: the capability works in a
/// reduced form and can be upgraded by requesting. An Always grant can
/// be provisional — the system may show its real upgrade prompt later
/// and the status can downgrade without any application action; the
/// status reports what the system reports. A system-wide Location
/// Services switch that is off surfaces as
/// ``PermissionAuthorization/denied``.
public struct LocationAlwaysStatus: PermissionStatus, Equatable {
    /// The normalized authorization state.
    public let authorization: PermissionAuthorization

    /// The granted precision, present only while access is granted.
    public let accuracy: LocationAccuracy?

    /// The follow-up action available to the application, if any.
    public let recovery: PermissionRecovery?

    /// Creates a status, typically for tests or previews.
    ///
    /// - Parameters:
    ///   - authorization: The normalized authorization state.
    ///   - accuracy: The granted precision, if access is granted.
    ///   - recovery: The follow-up action available to the application.
    public init(
        authorization: PermissionAuthorization,
        accuracy: LocationAccuracy?,
        recovery: PermissionRecovery?
    ) {
        self.authorization = authorization
        self.accuracy = accuracy
        self.recovery = recovery
    }
}
