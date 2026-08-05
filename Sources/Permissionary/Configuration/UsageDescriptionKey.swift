//
//  UsageDescriptionKey.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The Info.plist usage-description keys the supported capabilities
/// require.
///
/// Requests validate these keys before prompting; use the constants to
/// avoid typos when checking or documenting configuration.
public enum UsageDescriptionKey {
    /// The camera capability's key.
    public static let camera = "NSCameraUsageDescription"

    /// The microphone capability's key.
    public static let microphone = "NSMicrophoneUsageDescription"

    /// The photo library read/write capability's key.
    public static let photoLibrary = "NSPhotoLibraryUsageDescription"

    /// The photo library add-only capability's key.
    public static let photoLibraryAdd = "NSPhotoLibraryAddUsageDescription"

    /// The contacts capability's key.
    public static let contacts = "NSContactsUsageDescription"

    /// The when-in-use location capability's key, also required for the
    /// always capability.
    public static let locationWhenInUse = "NSLocationWhenInUseUsageDescription"

    /// The always location capability's key, required alongside
    /// ``locationWhenInUse``.
    public static let locationAlwaysAndWhenInUse = "NSLocationAlwaysAndWhenInUseUsageDescription"

    /// The app-tracking-transparency capability's key.
    public static let tracking = "NSUserTrackingUsageDescription"
}
