//
//  ContactStore.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import Contacts

struct ContactStoreShim: Sendable {
    var authorizationStatus: @Sendable () -> CNAuthorizationStatus
    var requestAccess: @Sendable () async -> Void

    static let live = ContactStoreShim(
        authorizationStatus: { CNContactStore.authorizationStatus(for: .contacts) },
        // The native call reports denial as a thrown error; the re-read
        // after the request is the source of truth, so the result and
        // error are deliberately unused.
        requestAccess: { _ = try? await CNContactStore().requestAccess(for: .contacts) }
    )
}

extension ContactsStatus {
    init(native: CNAuthorizationStatus) {
        switch native {
        case .notDetermined: self.init(authorization: .notDetermined, recovery: nil)
        case .authorized: self.init(authorization: .authorized, recovery: nil)
        case .limited: self.init(authorization: .limited, recovery: .manageLimitedSelection)
        case .denied: self.init(authorization: .denied, recovery: .openSettings)
        case .restricted: self.init(authorization: .restricted, recovery: nil)
        @unknown default:
            debugLogUnknownNativeState(rawValue: native.rawValue, capability: "contacts")
            self.init(authorization: .denied, recovery: .openSettings)
        }
    }
}

extension ContactsPermission {
    static func adapter(
        shim: ContactStoreShim,
        infoPlist: InfoPlistReader,
        coordination: RequestCoordination = RequestCoordination()
    ) -> ContactsPermission {
        let coalescer = RequestCoalescer<ContactsStatus>()
        return ContactsPermission(
            status: { ContactsStatus(native: shim.authorizationStatus()) },
            request: {
                try await coalescer.run {
                    try await coordination.serializer.run {
                        try await PromptOnceRequest.run(
                            usageDescriptionKey: "NSContactsUsageDescription",
                            infoPlist: infoPlist,
                            readNative: shim.authorizationStatus,
                            canPrompt: { $0 == .notDetermined },
                            prompt: shim.requestAccess,
                            makeStatus: { ContactsStatus(native: $0) }
                        )
                    }
                } ifCancelled: {
                    ContactsStatus(native: shim.authorizationStatus())
                }
            }
        )
    }
}
