//
//  NotificationsAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Synchronization
import Testing
import UserNotifications

@testable import Permissionary

private final class NotificationScript: Sendable {
    private let states: ShimScript<UNAuthorizationStatus>
    private let captured = Mutex<[UNAuthorizationOptions]>([])
    private let settings: NotificationSettings

    init(states: [UNAuthorizationStatus], settings: NotificationSettings = .allDisabled) {
        self.states = ShimScript(sequence: states)
        self.settings = settings
    }

    var requestCount: Int {
        captured.withLock { $0.count }
    }

    var capturedOptions: [UNAuthorizationOptions] {
        captured.withLock { $0 }
    }

    func shim() -> NotificationCenterShim {
        NotificationCenterShim(
            read: { (self.states.nextState(), self.settings) },
            requestAuthorization: { options in
                self.captured.withLock { $0.append(options) }
            }
        )
    }
}

struct NotificationsAdapterTests {
    private static let grantedSettings = NotificationSettings(
        alert: .enabled,
        sound: .enabled,
        badge: .disabled,
        lockScreen: .enabled,
        notificationCenter: .enabled,
        criticalAlert: .notSupported,
        timeSensitive: .notSupported,
        alertStyle: .banner
    )

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        let settings = NotificationSettings.allDisabled
        #expect(
            NotificationsStatus(native: .notDetermined, settings: settings)
                == NotificationsStatus(
                    authorization: .notDetermined,
                    grant: nil,
                    settings: settings,
                    recovery: nil
                )
        )
        #expect(
            NotificationsStatus(native: .denied, settings: settings)
                == NotificationsStatus(
                    authorization: .denied,
                    grant: nil,
                    settings: settings,
                    recovery: .openSettings
                )
        )
        #expect(
            NotificationsStatus(native: .authorized, settings: settings)
                == NotificationsStatus(
                    authorization: .authorized,
                    grant: .standard,
                    settings: settings,
                    recovery: nil
                )
        )
        #expect(
            NotificationsStatus(native: .provisional, settings: settings)
                == NotificationsStatus(
                    authorization: .limited,
                    grant: .provisional,
                    settings: settings,
                    recovery: nil
                )
        )
        #expect(
            NotificationsStatus(native: .ephemeral, settings: settings)
                == NotificationsStatus(
                    authorization: .authorized,
                    grant: .ephemeral,
                    settings: settings,
                    recovery: nil
                )
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(UNAuthorizationStatus(rawValue: 999))
        let status = NotificationsStatus(native: unknown, settings: .allDisabled)
        #expect(status.authorization == .denied)
        #expect(status.recovery == .openSettings)
        #expect(status.grant == nil)
    }

    @Test("Every known channel setting maps across")
    func settingMapping() throws {
        #expect(NotificationSetting(native: .notSupported) == .notSupported)
        #expect(NotificationSetting(native: .disabled) == .disabled)
        #expect(NotificationSetting(native: .enabled) == .enabled)
        let unknown = try #require(UNNotificationSetting(rawValue: 999))
        #expect(NotificationSetting(native: unknown) == .disabled)
    }

    @Test("Every known alert style maps across")
    func alertStyleMapping() throws {
        #expect(NotificationAlertStyle(native: .none) == NotificationAlertStyle.none)
        #expect(NotificationAlertStyle(native: .banner) == .banner)
        #expect(NotificationAlertStyle(native: .alert) == .alert)
        let unknown = try #require(UNAlertStyle(rawValue: 999))
        #expect(NotificationAlertStyle(native: unknown) == NotificationAlertStyle.none)
    }

    @Test("Domain options translate to their native flags")
    func optionsMapping() {
        #expect(NotificationOptions.alert.native == .alert)
        #expect(NotificationOptions.sound.native == .sound)
        #expect(NotificationOptions.badge.native == .badge)
        #expect(NotificationOptions.provisional.native == .provisional)
        #expect(NotificationOptions.criticalAlert.native == .criticalAlert)
        #expect(NotificationOptions.carPlay.native == .carPlay)
        #expect(
            NotificationOptions.providesAppNotificationSettings.native
                == .providesAppNotificationSettings
        )
        #expect(NotificationOptions.standard.native == [.alert, .sound, .badge])
        #expect(NotificationOptions([]).native == [])
    }

    @Test("Reading status never requests authorization")
    func statusNeverPrompts() async {
        let script = NotificationScript(states: [.notDetermined])
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        _ = await notifications.status()
        #expect(script.requestCount == 0)
    }

    @Test("Status carries the detailed settings snapshot")
    func statusCarriesSettings() async {
        let script = NotificationScript(states: [.authorized], settings: Self.grantedSettings)
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        let status = await notifications.status()
        #expect(status.settings == Self.grantedSettings)
        #expect(status.settings.alertStyle == .banner)
    }

    @Test("The default request uses the standard options")
    func defaultRequestUsesStandardOptions() async throws {
        let script = NotificationScript(states: [.authorized])
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        let status = try await notifications.request()
        #expect(status.authorization == .authorized)
        #expect(status.grant == .standard)
        #expect(script.capturedOptions == [[.alert, .sound, .badge]])
    }

    @Test("A provisional request is delivered quietly and reported as limited")
    func provisionalRequest() async throws {
        let script = NotificationScript(states: [.provisional])
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        let status = try await notifications.request([.provisional, .badge])
        #expect(status.authorization == .limited)
        #expect(status.grant == .provisional)
        #expect(script.capturedOptions == [[.provisional, .badge]])
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = NotificationScript(states: [.denied])
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        let status = try await notifications.request()
        #expect(status.authorization == .denied)
        #expect(status.recovery == .openSettings)
    }

    @Test("Requests always run natively and re-read the final state")
    func requestAfterDenialStillRuns() async throws {
        let script = NotificationScript(states: [.denied])
        let notifications = NotificationsPermission.adapter(shim: script.shim())
        let status = try await notifications.request()
        #expect(status.authorization == .denied)
        #expect(script.requestCount == 1)
    }
}
