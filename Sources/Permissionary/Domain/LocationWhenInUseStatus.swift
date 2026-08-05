//
//  LocationWhenInUseStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The when-in-use location capability's typed status.
///
/// An Always grant satisfies this capability and is reported as
/// ``PermissionAuthorization/authorized``. A system-wide Location
/// Services switch that is off surfaces as
/// ``PermissionAuthorization/denied``, exactly as the system reports it.
public struct LocationWhenInUseStatus: PermissionStatus, Equatable {
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
