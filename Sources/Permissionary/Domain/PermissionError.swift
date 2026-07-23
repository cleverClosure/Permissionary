//
//  PermissionError.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// An exceptional failure raised while preparing or executing a request.
///
/// Ordinary permission outcomes are values, not errors: denial,
/// restriction, and limited grants are reported through statuses. Errors
/// are reserved for conditions the application must fix or cannot
/// meaningfully handle.
public enum PermissionError: Error, Sendable, Equatable {
    /// A required usage-description key is missing from the application's
    /// Info.plist. Requesting without it would terminate the process, so
    /// the request fails first with the exact key to add.
    case missingUsageDescription(key: String)

    /// Required configuration beyond usage descriptions is missing or
    /// inconsistent. The reason describes what to fix.
    case invalidConfiguration(reason: String)

    /// The operation cannot be performed in the current environment.
    case unsupported

    /// An Apple framework reported an error that has no richer
    /// representation in this library. The description preserves the
    /// diagnostic without exposing a framework error type.
    case underlying(description: String)
}
