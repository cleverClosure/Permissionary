//
//  AuthorizationBadge.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary
import SwiftUI

struct AuthorizationBadge: View {
    let authorization: PermissionAuthorization?

    var body: some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        guard let authorization else {
            return "loading"
        }
        return String(describing: authorization)
    }

    private var color: Color {
        switch authorization {
        case .authorized: .green
        case .limited: .orange
        case .denied, .restricted: .red
        case .unavailable, .notDetermined, nil: .gray
        }
    }
}
