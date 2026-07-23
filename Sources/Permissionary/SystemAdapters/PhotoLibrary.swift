//
//  PhotoLibrary.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Photos

struct PhotoLibraryShim: Sendable {
    var authorizationStatus: @Sendable () -> PHAuthorizationStatus
    var requestAuthorization: @Sendable () async -> Void

    static func live(access: PHAccessLevel) -> PhotoLibraryShim {
        PhotoLibraryShim(
            authorizationStatus: { PHPhotoLibrary.authorizationStatus(for: access) },
            requestAuthorization: { _ = await PHPhotoLibrary.requestAuthorization(for: access) }
        )
    }
}

extension PhotosReadWriteStatus {
    init(native: PHAuthorizationStatus) {
        switch native {
        case .notDetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .authorized: self.init(authorization: .authorized, recovery: nil)
        case .limited: self.init(authorization: .limited, recovery: .manageLimitedSelection)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        case .restricted: self.init(authorization: .restricted, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "photosReadWrite")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension PhotosAddOnlyStatus {
    init(native: PHAuthorizationStatus) {
        switch native {
        case .notDetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .authorized: self.init(authorization: .authorized, recovery: nil)
        case .limited: self.init(authorization: .limited, recovery: nil)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        case .restricted: self.init(authorization: .restricted, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "photosAddOnly")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension PhotosReadWritePermission {
    static func adapter(
        shim: PhotoLibraryShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> PhotosReadWritePermission {
        let coalescer = RequestCoalescer<PhotosReadWriteStatus>()
        return PhotosReadWritePermission(
            status: { PhotosReadWriteStatus(native: shim.authorizationStatus()) },
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        try await PromptOnceRequest.run(
                            usageDescriptionKey: "NSPhotoLibraryUsageDescription",
                            infoPlist: infoPlist,
                            readNative: shim.authorizationStatus,
                            canPrompt: { $0 == .notDetermined },
                            prompt: shim.requestAuthorization,
                            makeStatus: { PhotosReadWriteStatus(native: $0) }
                        )
                    }
                } ifCancelled: {
                    PhotosReadWriteStatus(native: shim.authorizationStatus())
                }
            }
        )
    }
}

extension PhotosAddOnlyPermission {
    static func adapter(
        shim: PhotoLibraryShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> PhotosAddOnlyPermission {
        let coalescer = RequestCoalescer<PhotosAddOnlyStatus>()
        return PhotosAddOnlyPermission(
            status: { PhotosAddOnlyStatus(native: shim.authorizationStatus()) },
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        try await PromptOnceRequest.run(
                            usageDescriptionKey: "NSPhotoLibraryAddUsageDescription",
                            infoPlist: infoPlist,
                            readNative: shim.authorizationStatus,
                            canPrompt: { $0 == .notDetermined },
                            prompt: shim.requestAuthorization,
                            makeStatus: { PhotosAddOnlyStatus(native: $0) }
                        )
                    }
                } ifCancelled: {
                    PhotosAddOnlyStatus(native: shim.authorizationStatus())
                }
            }
        )
    }
}
