//
//  LocationAccuracy.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The precision level the user granted for location access.
///
/// Mirrors the system's accuracy authorization: the user can grant full
/// precision or approximate location. Unknown future precision levels
/// are reported as ``reduced`` so the application never overstates the
/// precision it has.
public enum LocationAccuracy: Sendable, Equatable {
    /// Precise location.
    case full

    /// Approximate location.
    case reduced
}
