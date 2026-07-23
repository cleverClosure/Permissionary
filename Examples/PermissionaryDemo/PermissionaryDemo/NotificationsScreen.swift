//
//  NotificationsScreen.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

@MainActor
struct NotificationsScreen: View {
    let model: NotificationsPermissionModel

    @State private var alert = true
    @State private var sound = true
    @State private var badge = true
    @State private var provisional = false

    var body: some View {
        Form {
            statusSection
            if let settings = model.status?.settings {
                settingsSection(settings)
            }
            optionsSection
            actionsSection
            recoverySection
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Authorization") {
                AuthorizationBadge(authorization: model.status?.authorization)
            }
            LabeledContent("Grant", value: grantLabel)
            Text("A provisional request never prompts and delivers quietly.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func settingsSection(_ settings: NotificationSettings) -> some View {
        Section("Settings Snapshot") {
            settingRow("Alert", settings.alert)
            settingRow("Sound", settings.sound)
            settingRow("Badge", settings.badge)
            settingRow("Lock Screen", settings.lockScreen)
            settingRow("Notification Center", settings.notificationCenter)
            settingRow("Critical Alert", settings.criticalAlert)
            settingRow("Time Sensitive", settings.timeSensitive)
            LabeledContent("Alert Style", value: String(describing: settings.alertStyle))
        }
    }

    private var optionsSection: some View {
        Section("Request Options") {
            Toggle("Alert", isOn: $alert)
            Toggle("Sound", isOn: $sound)
            Toggle("Badge", isOn: $badge)
            Toggle("Provisional", isOn: $provisional)
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            RequestRow {
                _ = try await model.request(selectedOptions)
            }
            Button("Refresh") {
                Task {
                    await model.refresh()
                }
            }
        }
    }

    @ViewBuilder
    private var recoverySection: some View {
        if model.status?.recovery == .openSettings {
            Section("Recovery") {
                OpenSettingsButton()
            }
        }
    }

    private var selectedOptions: NotificationOptions {
        var options: NotificationOptions = []
        if alert {
            options.insert(.alert)
        }
        if sound {
            options.insert(.sound)
        }
        if badge {
            options.insert(.badge)
        }
        if provisional {
            options.insert(.provisional)
        }
        return options
    }

    private var grantLabel: String {
        guard let grant = model.status?.grant else {
            return "none"
        }
        return String(describing: grant)
    }

    private func settingRow(_ name: String, _ setting: NotificationSetting) -> some View {
        LabeledContent(name, value: String(describing: setting))
    }
}
