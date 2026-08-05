//
//  PhotosAddOnlyAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Photos
import Testing

@testable import Permissionary

struct PhotosAddOnlyAdapterTests {
    private func makePhotos(
        script: ShimScript<PHAuthorizationStatus>,
        usageDescription: String? = "Saves photos you create"
    ) -> PhotosAddOnlyPermission {
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
            PhotosAddOnlyStatus(native: .notDetermined)
                == PhotosAddOnlyStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            PhotosAddOnlyStatus(native: .authorized)
                == PhotosAddOnlyStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            PhotosAddOnlyStatus(native: .limited)
                == PhotosAddOnlyStatus(authorization: .limited, recovery: nil)
        )
        #expect(
            PhotosAddOnlyStatus(native: .denied)
                == PhotosAddOnlyStatus(authorization: .denied, recovery: .openSettings)
        )
        #expect(
            PhotosAddOnlyStatus(native: .restricted)
                == PhotosAddOnlyStatus(authorization: .restricted, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(PHAuthorizationStatus(rawValue: 999))
        #expect(
            PhotosAddOnlyStatus(native: unknown)
                == PhotosAddOnlyStatus(authorization: .denied, recovery: .openSettings)
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
        #expect(status == PhotosAddOnlyStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.notDetermined, .denied)
        let status = try await makePhotos(script: script).request()
        #expect(status == PhotosAddOnlyStatus(authorization: .denied, recovery: .openSettings))
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
            throws: PermissionError.missingUsageDescription(
                key: "NSPhotoLibraryAddUsageDescription"
            )
        ) {
            _ = try await photos.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<PHAuthorizationStatus>(.authorized)
        let photos = makePhotos(script: script, usageDescription: nil)
        let status = try await photos.request()
        #expect(status.authorization == .authorized)
    }
}
