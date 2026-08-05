# Project

## Problem

iOS applications commonly need to request several system permissions, but Apple frameworks expose different APIs, state models, lifecycle rules, and recovery behavior.

Existing permission libraries are often outdated, abandoned, callback-based, or not designed for Swift 6 concurrency and SwiftUI.

## Target users

Developers building modern SwiftUI applications for current iOS versions.

## Goals

- Provide one consistent entry point for common permissions
- Use async/await throughout the public API
- Preserve important framework-specific permission semantics
- Support Swift 6 strict concurrency
- Provide a small SwiftUI-first integration layer
- Make denial and Settings recovery predictable
- Remain easy to test
- Avoid external runtime dependencies

## Non-goals

Version 1 will not provide:

- Custom pre-permission education screens
- Automatic requests on app launch or view appearance
- Analytics or telemetry
- Permission-state persistence
- Private Settings URL schemes
- Objective-C support
- UIKit-first APIs
- macOS, watchOS, tvOS, or visionOS support
- App extension support
- Deprecated Apple permission APIs
- Complete onboarding-flow orchestration

The library manages permission state and system interaction. The host application owns product-specific UX.

## Version 1 scope

- Camera
- Location: When In Use
- Location: Always
- Notifications
- Photos: Read/Write
- Photos: Add Only
- Contacts
- Microphone
- App Tracking Transparency
- Async status and request APIs
- SwiftUI environment integration
- Explicit Settings recovery
- Injectable live and test implementations
- Demo application for manual verification

## Capability roadmap

Version 1 capabilities are listed above. Beyond version 1:

| Capability | Status | Reason |
|---|---|---|
| Calendar and Reminders | Planned | Modern access levels (full, write-only) fit the existing capability model |
| Speech recognition | Planned | Explicit request API; commonly paired with microphone |
| Motion & Fitness | Under evaluation | Prompts are triggered by data access rather than an explicit request API |
| Bluetooth | Under evaluation | Authorization is entangled with radio state and manager lifecycle |
| Local Network | Under evaluation | No reliable public status API |
| HealthKit | Not planned | Per-record-type authorization does not fit a general-purpose wrapper |
| Face ID / Local Authentication | Not planned | Policy-evaluation API, not a one-time permission grant |
| Screen Time / Family Controls | Not planned | Separate authorization ecosystem with its own UI requirements |

Requests for new capabilities should reference this table. "Not planned" entries require a design that resolves the stated reason.

## Design principles

1. Reading state never causes a prompt.
2. Denial is a valid result, not an error.
3. Permission state is not reduced to a Boolean.
4. Settings recovery is explicit.
5. Framework-specific details are preserved.
6. Public values are immutable and Sendable.
7. System behavior is wrapped, not hidden.
8. The API should be small enough to learn from examples.
9. Stable releases never depend on beta SDKs.
10. No abstraction is added without a real use case.

## Platform support policy

Initial target:

- iOS 18+
- Swift 6 language mode
- Stable Xcode releases
- Swift Package Manager only

Out of scope for version 1, even where technically possible:

- App extensions (Settings recovery and several request flows are unavailable or behave differently)
- iPad apps on Mac, Mac Catalyst, and visionOS compatibility mode (unverified; best effort only)

The minimum iOS version may increase in future major releases when doing so materially improves the implementation or public API.

## Definition of done for version 1

- Every supported permission has a completed behavior matrix
- All public APIs are documented
- Swift 6 strict concurrency checks pass
- Mapping and contract tests pass
- The demo app covers all supported permissions
- Manual device scenarios are documented and verified
- Settings recovery behaves consistently
- No continuation leaks or duplicate system prompts occur
- README examples compile
- The privacy manifest audit is complete and reflected in the package
- LICENSE and contribution guidelines are published
- A tagged semantic-versioned release can be produced
