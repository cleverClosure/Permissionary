//
//  Camera.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import AVFoundation

struct CameraShim: Sendable {
    var authorizationStatus: @Sendable () -> AVAuthorizationStatus
    var requestAccess: @Sendable () async -> Bool

    static let live = CameraShim(
        authorizationStatus: { AVCaptureDevice.authorizationStatus(for: .video) },
        requestAccess: { await AVCaptureDevice.requestAccess(for: .video) }
    )
}

extension CameraStatus {
    init(native: AVAuthorizationStatus) {
        switch native {
        case .notDetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .authorized: self.init(authorization: .authorized, recovery: nil)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        case .restricted: self.init(authorization: .restricted, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "camera")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension CameraPermission {
    static func adapter(shim: CameraShim, infoPlist: InfoPlistReader) -> CameraPermission {
        CameraPermission(
            status: { CameraStatus(native: shim.authorizationStatus()) },
            request: {
                try await PromptOnceRequest.run(
                    usageDescriptionKey: "NSCameraUsageDescription",
                    infoPlist: infoPlist,
                    readNative: shim.authorizationStatus,
                    canPrompt: { $0 == .notDetermined },
                    prompt: { _ = await shim.requestAccess() },
                    makeStatus: { CameraStatus(native: $0) }
                )
            }
        )
    }
}
