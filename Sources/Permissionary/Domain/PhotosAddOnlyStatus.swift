//
//  PhotosAddOnlyStatus.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The photo library add-only capability's typed status.
///
/// Add-only access is independent from read/write access: it permits
/// saving new assets without exposing the existing library.
public struct PhotosAddOnlyStatus: PermissionStatus, Equatable {
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
