//
//  CapabilityScreen.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

@MainActor
struct CapabilityScreen<Status: PermissionStatus, Details: View>: View {
    let title: String
    let usageKeys: [String]
    let status: Status?
    let note: String?
    let request: () async throws -> Status
    let refresh: () async -> Void
    let manageLimitedSelection: (() -> Void)?
    @ViewBuilder let details: (Status) -> Details

    @Environment(\.permissions) private var permissions

    init(
        title: String,
        usageKeys: [String],
        status: Status?,
        note: String? = nil,
        request: @escaping () async throws -> Status,
        refresh: @escaping () async -> Void,
        manageLimitedSelection: (() -> Void)? = nil,
        @ViewBuilder details: @escaping (Status) -> Details
    ) {
        self.title = title
        self.usageKeys = usageKeys
        self.status = status
        self.note = note
        self.request = request
        self.refresh = refresh
        self.manageLimitedSelection = manageLimitedSelection
        self.details = details
    }

    var body: some View {
        Form {
            statusSection
            if !usageKeys.isEmpty {
                configurationSection
            }
            actionsSection
            recoverySection
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var statusSection: some View {
        Section("Status") {
            LabeledContent("Authorization") {
                AuthorizationBadge(authorization: status?.authorization)
            }
            LabeledContent("Recovery", value: recoveryLabel)
            if let status {
                details(status)
            }
            if let note {
                Text(note)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var configurationSection: some View {
        Section("Configuration") {
            ForEach(usageKeys, id: \.self) { key in
                LabeledContent(key) {
                    Image(systemName: usageKeyIsPresent(key) ? "checkmark.circle" : "xmark.circle")
                        .foregroundStyle(usageKeyIsPresent(key) ? .green : .red)
                }
                .font(.footnote)
            }
        }
    }

    private var actionsSection: some View {
        Section("Actions") {
            RequestRow {
                _ = try await request()
            }
            Button("Refresh") {
                Task {
                    await refresh()
                }
            }
        }
    }

    @ViewBuilder
    private var recoverySection: some View {
        if status?.recovery != nil {
            Section("Recovery") {
                if status?.recovery == .openSettings {
                    OpenSettingsButton()
                }
                if status?.recovery == .manageLimitedSelection, let manageLimitedSelection {
                    Button("Manage Limited Selection") {
                        manageLimitedSelection()
                    }
                }
            }
        }
    }

    private var recoveryLabel: String {
        switch status?.recovery {
        case .openSettings: "openSettings"
        case .manageLimitedSelection: "manageLimitedSelection"
        case nil: "none"
        }
    }

    private func usageKeyIsPresent(_ key: String) -> Bool {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return false
        }
        return !value.isEmpty
    }
}

extension CapabilityScreen where Details == EmptyView {
    init(
        title: String,
        usageKeys: [String],
        status: Status?,
        note: String? = nil,
        request: @escaping () async throws -> Status,
        refresh: @escaping () async -> Void,
        manageLimitedSelection: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            usageKeys: usageKeys,
            status: status,
            note: note,
            request: request,
            refresh: refresh,
            manageLimitedSelection: manageLimitedSelection,
            details: { _ in EmptyView() }
        )
    }
}

@MainActor
struct RequestRow: View {
    let perform: () async throws -> Void

    @State private var isRequesting = false
    @State private var lastError: String?

    var body: some View {
        Button {
            run()
        } label: {
            if isRequesting {
                ProgressView()
            } else {
                Text("Request")
            }
        }
        .disabled(isRequesting)
        if let lastError {
            Text(lastError)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }

    private func run() {
        isRequesting = true
        lastError = nil
        Task {
            do {
                try await perform()
            } catch {
                lastError = String(describing: error)
            }
            isRequesting = false
        }
    }
}

@MainActor
struct OpenSettingsButton: View {
    @Environment(\.permissions) private var permissions

    var body: some View {
        Button("Open Settings") {
            Task {
                await permissions.openSettings()
            }
        }
    }
}
