//
//  NotificationCenter.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import UserNotifications

struct NotificationCenterShim: Sendable {
    var read: @Sendable () async -> (status: UNAuthorizationStatus, settings: NotificationSettings)
    var requestAuthorization: @Sendable (UNAuthorizationOptions) async -> Void

    static let live = NotificationCenterShim(
        read: {
            let native = await UNUserNotificationCenter.current().notificationSettings()
            return (native.authorizationStatus, NotificationSettings(native: native))
        },
        requestAuthorization: { options in
            // Denial arrives as a false result, and errors carry no state
            // the re-read afterward would miss, so both are deliberately
            // unused.
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: options)
        }
    )
}

extension NotificationSetting {
    init(native: UNNotificationSetting) {
        switch native {
        case .notSupported: self = .notSupported
        case .disabled: self = .disabled
        case .enabled: self = .enabled
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "notificationSetting")
            self = .disabled
        }
    }
}

extension NotificationAlertStyle {
    init(native: UNAlertStyle) {
        switch native {
        case .none: self = .none
        case .banner: self = .banner
        case .alert: self = .alert
        @unknown default:
            debugLogUnknownNativeState(
                rawValue: native.rawValue,
                capability: "notificationAlertStyle"
            )
            self = .none
        }
    }
}

extension NotificationSettings {
    init(native: UNNotificationSettings) {
        self.init(
            alert: NotificationSetting(native: native.alertSetting),
            sound: NotificationSetting(native: native.soundSetting),
            badge: NotificationSetting(native: native.badgeSetting),
            lockScreen: NotificationSetting(native: native.lockScreenSetting),
            notificationCenter: NotificationSetting(native: native.notificationCenterSetting),
            criticalAlert: NotificationSetting(native: native.criticalAlertSetting),
            timeSensitive: NotificationSetting(native: native.timeSensitiveSetting),
            alertStyle: NotificationAlertStyle(native: native.alertStyle)
        )
    }
}

extension NotificationsStatus {
    init(native: UNAuthorizationStatus, settings: NotificationSettings) {
        switch native {
        case .notDetermined:
            self.init(authorization: .notDetermined, grant: nil, settings: settings, recovery: nil)
        case .denied:
            self.init(
                authorization: .denied,
                grant: nil,
                settings: settings,
                recovery: .openSettings
            )
        case .authorized:
            self.init(
                authorization: .authorized,
                grant: .standard,
                settings: settings,
                recovery: nil
            )
        case .provisional:
            self.init(
                authorization: .limited,
                grant: .provisional,
                settings: settings,
                recovery: nil
            )
        case .ephemeral:
            self.init(
                authorization: .authorized,
                grant: .ephemeral,
                settings: settings,
                recovery: nil
            )
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "notifications")
            self.init(
                authorization: .denied,
                grant: nil,
                settings: settings,
                recovery: .openSettings
            )
        }
    }
}

extension NotificationOptions {
    var native: UNAuthorizationOptions {
        var result: UNAuthorizationOptions = []
        if contains(.alert) { result.insert(.alert) }
        if contains(.sound) { result.insert(.sound) }
        if contains(.badge) { result.insert(.badge) }
        if contains(.provisional) { result.insert(.provisional) }
        if contains(.criticalAlert) { result.insert(.criticalAlert) }
        if contains(.carPlay) { result.insert(.carPlay) }
        if contains(.providesAppNotificationSettings) {
            result.insert(.providesAppNotificationSettings)
        }
        return result
    }
}

extension NotificationsPermission {
    static func adapter(
        shim: NotificationCenterShim,
        coordination: RequestCoordination = RequestCoordination()
    ) -> NotificationsPermission {
        let coalescer = RequestCoalescer<NotificationsStatus>()
        let hub = StatusHub<NotificationsStatus>()
        return NotificationsPermission(
            status: {
                let current = await shim.read()
                let status = NotificationsStatus(native: current.status, settings: current.settings)
                await hub.publish(status)
                return status
            },
            request: { options in
                try await coalescer.run {
                    await coordination.serializer.run {
                        await shim.requestAuthorization(options.native)
                        let final = await shim.read()
                        let status = NotificationsStatus(
                            native: final.status,
                            settings: final.settings
                        )
                        await hub.publish(status)
                        return status
                    }
                } ifCancelled: {
                    let current = await shim.read()
                    return NotificationsStatus(native: current.status, settings: current.settings)
                }
            },
            updates: { await hub.stream() }
        )
    }
}
