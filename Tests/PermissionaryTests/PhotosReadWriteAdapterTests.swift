//
//  PhotosReadWriteAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Photos
import Testing

@testable import Permissionary

struct PhotosReadWriteAdapterTests {
    private func makePhotos(
        script: ShimScript<PHAuthorizationStatus>,
        usageDescription: String? = "Shows your photos"
    ) -> PhotosReadWritePermission {
        .adapter(
            shim: PhotoLibraryShim(
                authorizationStatus: { script.nextState() },
                requestAuthorization: { script.recordPrompt() }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            PhotosReadWriteStatus(native: .notDetermined)
                == PhotosReadWriteStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            PhotosReadWriteStatus(native: .authorized)
                == PhotosReadWriteStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            PhotosReadWriteStatus(native: .limited)
                == PhotosReadWriteStatus(authorization: .limited, recovery: .manageLimitedSelection)
        )
        #expect(
            PhotosReadWriteStatus(native: .denied)
                == PhotosReadWriteStatus(authorization: .denied, recovery: .openSettings)
        )
        #expect(
            PhotosReadWriteStatus(native: .restricted)
                == PhotosReadWriteStatus(authorization: .restricted, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(PHAuthorizationStatus(rawValue: 999))
        #expect(
            PhotosReadWriteStatus(native: unknown)
                == PhotosReadWriteStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined)
        let photos = makePhotos(script: script)
        _ = await photos.status()
        #expect(script.promptCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined, .authorized)
        let photos = makePhotos(script: script)
        let status = try await photos.request()
        #expect(status == PhotosReadWriteStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("A limited grant is reported as a successful status with selection recovery")
    func requestLimited() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined, .limited)
        let status = try await makePhotos(script: script).request()
        #expect(
            status
                == PhotosReadWriteStatus(authorization: .limited, recovery: .manageLimitedSelection)
        )
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined, .denied)
        let status = try await makePhotos(script: script).request()
        #expect(status == PhotosReadWriteStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.denied)
        let photos = makePhotos(script: script)
        let status = try await photos.request()
        #expect(status.authorization == .denied)
        #expect(script.promptCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined)
        let photos = makePhotos(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(key: "NSPhotoLibraryUsageDescription")
        ) {
            _ = try await photos.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.limited)
        let photos = makePhotos(script: script, usageDescription: nil)
        let status = try await photos.request()
        #expect(status.authorization == .limited)
    }
}
