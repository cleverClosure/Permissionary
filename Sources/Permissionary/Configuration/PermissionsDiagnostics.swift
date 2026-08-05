//
//  PermissionsDiagnostics.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// A standalone entry point for surfacing configuration problems before
/// any request is made.
///
/// Every issue returned here is exactly the error the corresponding
/// `request()` would throw, so a debug-build startup check catches
/// configuration mistakes without triggering a single prompt.
public enum PermissionsDiagnostics {
    /// Returns one issue for each required usage-description key that is
    /// missing or empty, across every supported capability.
    ///
    /// Applications that use a subset of capabilities can ignore issues
    /// for keys they never request, comparing against
    /// ``UsageDescriptionKey`` constants.
    ///
    /// - Returns: The configuration issues, in a stable order.
    public static func configurationIssues() -> [PermissionError] {
        configurationIssues(infoPlist: .live)
    }

    static func configurationIssues(infoPlist: InfoPlistReader) -> [PermissionError] {
        requiredKeys.compactMap { key in
            guard let description = infoPlist.string(key), !description.isEmpty else {
                return .missingUsageDescription(key: key)
            }
            return nil
        }
    }

    private static let requiredKeys = [
        UsageDescriptionKey.camera,
        UsageDescriptionKey.microphone,
        UsageDescriptionKey.photoLibrary,
        UsageDescriptionKey.photoLibraryAdd,
        UsageDescriptionKey.contacts,
        UsageDescriptionKey.locationWhenInUse,
        UsageDescriptionKey.locationAlwaysAndWhenInUse,
        UsageDescriptionKey.tracking,
    ]
}
