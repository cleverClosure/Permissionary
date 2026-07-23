//
//  DiagnosticsScreen.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

@MainActor
struct DiagnosticsScreen: View {
    private let issues = PermissionsDiagnostics.configurationIssues()

    var body: some View {
        Form {
            if issues.isEmpty {
                Section {
                    Label("No configuration issues", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                } footer: {
                    Text(
                        "Every usage-description key is present, so no request can "
                            + "fail configuration validation."
                    )
                }
            } else {
                Section("Issues") {
                    ForEach(Array(issues.enumerated()), id: \.offset) { _, issue in
                        Text(String(describing: issue))
                            .font(.footnote)
                    }
                }
            }
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}
