//
//  PermissionsClient.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The injectable entry point for reading and requesting permissions.
///
/// Every operation is exposed as a replaceable value, so tests and
/// previews construct a client from deterministic pieces without a global
/// singleton. Use ``live`` for the client backed by the real system
/// frameworks. Capability accessors are added as their adapters are
/// implemented.
public struct PermissionsClient: Sendable {
    /// The camera capability.
    public var camera: CameraPermission

    /// The when-in-use location capability.
    public var locationWhenInUse: LocationWhenInUsePermission

    /// The always location capability.
    public var locationAlways: LocationAlwaysPermission

    /// The photo library read/write capability.
    public var photosReadWrite: PhotosReadWritePermission

    /// The photo library add-only capability.
    public var photosAddOnly: PhotosAddOnlyPermission

    /// The contacts capability.
    public var contacts: ContactsPermission

    /// The microphone capability.
    public var microphone: MicrophonePermission

    /// The app-tracking-transparency capability.
    public var tracking: TrackingPermission

    /// Opens the application's page in the Settings app.
    ///
    /// Call this only from an explicit user action, typically after a
    /// status reports ``PermissionRecovery/openSettings``. The library
    /// never opens Settings automatically.
    public var openSettings: @Sendable () async -> Void

    /// Creates a client from its operations.
    ///
    /// - Parameters:
    ///   - camera: The camera capability.
    ///   - locationWhenInUse: The when-in-use location capability.
    ///   - locationAlways: The always location capability.
    ///   - photosReadWrite: The photo library read/write capability.
    ///   - photosAddOnly: The photo library add-only capability.
    ///   - contacts: The contacts capability.
    ///   - microphone: The microphone capability.
    ///   - tracking: The app-tracking-transparency capability.
    ///   - openSettings: Opens the application's page in Settings.
    public init(
        camera: CameraPermission,
        locationWhenInUse: LocationWhenInUsePermission,
        locationAlways: LocationAlwaysPermission,
        photosReadWrite: PhotosReadWritePermission,
        photosAddOnly: PhotosAddOnlyPermission,
        contacts: ContactsPermission,
        microphone: MicrophonePermission,
        tracking: TrackingPermission,
        openSettings: @escaping @Sendable () async -> Void
    ) {
        self.camera = camera
        self.locationWhenInUse = locationWhenInUse
        self.locationAlways = locationAlways
        self.photosReadWrite = photosReadWrite
        self.photosAddOnly = photosAddOnly
        self.contacts = contacts
        self.microphone = microphone
        self.tracking = tracking
        self.openSettings = openSettings
    }
}
