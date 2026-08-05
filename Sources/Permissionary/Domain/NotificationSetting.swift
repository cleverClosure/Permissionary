//
//  NotificationSetting.swift
//  Permissionary
//
//  Created by Tim Isaev
//

/// The state of one notification delivery channel.
public enum NotificationSetting: Sendable, Equatable {
    /// The channel does not apply to this device or application.
    case notSupported

    /// The user turned the channel off.
    case disabled

    /// The user turned the channel on.
    case enabled
}
