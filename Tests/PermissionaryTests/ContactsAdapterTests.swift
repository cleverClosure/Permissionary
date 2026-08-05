//
//  ContactsAdapterTests.swift
//  PermissionaryTests
//
//  Created by Tim Isaev
//

import Contacts
import Testing

@testable import Permissionary

struct ContactsAdapterTests {
    private func makeContacts(
        script: ShimScript<CNAuthorizationStatus>,
        usageDescription: String? = "Finds your friends"
    ) -> ContactsPermission {
        .adapter(
            shim: ContactStoreShim(
                authorizationStatus: { script.nextState() },
                requestAccess: { script.recordPrompt() }
            ),
            infoPlist: InfoPlistReader(string: { _ in usageDescription })
        )
    }

    @Test("Every known native state maps to its normalized pair")
    func knownStates() {
        #expect(
            ContactsStatus(native: .notDetermined)
                == ContactsStatus(authorization: .notDetermined, recovery: nil)
        )
        #expect(
            ContactsStatus(native: .authorized)
                == ContactsStatus(authorization: .authorized, recovery: nil)
        )
        #expect(
            ContactsStatus(native: .limited)
                == ContactsStatus(authorization: .limited, recovery: .manageLimitedSelection)
        )
        #expect(
            ContactsStatus(native: .denied)
                == ContactsStatus(authorization: .denied, recovery: .openSettings)
        )
        #expect(
            ContactsStatus(native: .restricted)
                == ContactsStatus(authorization: .restricted, recovery: nil)
        )
    }

    @Test("Unknown future native states map to denied with Settings recovery")
    func unknownState() throws {
        let unknown = try #require(CNAuthorizationStatus(rawValue: 999))
        #expect(
            ContactsStatus(native: unknown)
                == ContactsStatus(authorization: .denied, recovery: .openSettings)
        )
    }

    @Test("Reading status never prompts")
    func statusNeverPrompts() async {
        let script = ShimScript<CNAuthorizationStatus>(.notDetermined)
        let contacts = makeContacts(script: script)
        _ = await contacts.status()
        #expect(script.promptCount == 0)
    }

    @Test("Request from not determined prompts and reports the granted state")
    func requestGranted() async throws {
        let script = ShimScript<CNAuthorizationStatus>(.notDetermined, .authorized)
        let contacts = makeContacts(script: script)
        let status = try await contacts.request()
        #expect(status == ContactsStatus(authorization: .authorized, recovery: nil))
        #expect(script.promptCount == 1)
    }

    @Test("A limited grant is reported as a successful status with selection recovery")
    func requestLimited() async throws {
        let script = ShimScript<CNAuthorizationStatus>(.notDetermined, .limited)
        let status = try await makeContacts(script: script).request()
        #expect(
            status == ContactsStatus(authorization: .limited, recovery: .manageLimitedSelection)
        )
    }

    @Test("Denial is reported as a status, not an error")
    func requestDenied() async throws {
        let script = ShimScript<CNAuthorizationStatus>(.notDetermined, .denied)
        let status = try await makeContacts(script: script).request()
        #expect(status == ContactsStatus(authorization: .denied, recovery: .openSettings))
    }

    @Test("Request after denial returns the current status without prompting")
    func requestAfterDenial() async throws {
        let script = ShimScript<CNAuthorizationStatus>(.denied)
        let contacts = makeContacts(script: script)
        let status = try await contacts.request()
        #expect(status.authorization == .denied)
        #expect(script.promptCount == 0)
    }

    @Test("A missing usage description fails before any prompt")
    func missingUsageDescription() async {
        let script = ShimScript<CNAuthorizationStatus>(.notDetermined)
        let contacts = makeContacts(script: script, usageDescription: nil)
        await #expect(
            throws: PermissionError.missingUsageDescription(key: "NSContactsUsageDescription")
        ) {
            _ = try await contacts.request()
        }
        #expect(script.promptCount == 0)
    }

    @Test("Validation is skipped when no prompt is possible")
    func noValidationWithoutPrompt() async throws {
        let script = ShimScript<CNAuthorizationStatus>(.limited)
        let contacts = makeContacts(script: script, usageDescription: nil)
        let status = try await contacts.request()
        #expect(status.authorization == .limited)
    }
}
