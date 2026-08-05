# Testing Strategy

Permission APIs depend on system state, process lifecycle, Settings, hardware, and one-time prompts. Unit tests alone are insufficient.

## Test layers

### 1. Mapping tests

Test every native state to library-state mapping.

Required coverage:

- Known native values
- Limited or provisional values
- Restricted values
- Unknown future values
- Recovery mapping
- Permission-specific details

Mapping functions should be pure where possible.

### 2. Contract tests

Contract tests run against scripted fakes of each adapter's native shim. The real shim is
deliberately thin and is verified manually through the demo app on physical devices.

Every adapter must satisfy shared behavioral rules:

- `status()` never requests permission
- `request()` returns the final observed state
- Denial does not throw
- Restricted access does not throw
- Missing configuration produces a descriptive error
- Duplicate requests behave deterministically
- Repeated requests do not invent a system prompt
- Cancellation does not leak continuations
- Every continuation resumes exactly once
- Unknown native states do not crash

Use shared test suites where the behavior is truly common.

### 3. Coordination tests

Test the request coordinator independently.

Scenarios:

- Two callers request the same capability
- Two callers cancel independently
- One caller cancels while another waits
- Different permission requests arrive simultaneously
- Native callback fires once
- Native callback fires unexpectedly more than once
- Adapter throws before presenting
- App becomes inactive during a request
- Final status differs from callback result

### 4. SwiftUI tests

Test:

- Environment injection
- Initial status loading
- Explicit request action
- Loading state
- Denied state
- Limited state
- Error presentation
- Settings recovery
- Refresh when the scene becomes active
- Fake clients and deterministic previews

Do not test Apple system prompts through ordinary SwiftUI unit tests.

### 5. Demo-app verification

The demo app is the manual integration harness. It lives in
`Examples/PermissionaryDemo` and drives every capability through the
library's observable models and environment injection.

Each permission screen should display:

- Current normalized authorization
- Typed details
- Recovery action
- Last error
- Whether configuration is valid
- Whether a request is in progress

## Tools

Preferred:

- Swift Testing for package unit and contract tests
- XCTest only where required for UI or system integration
- DocC examples compiled as part of CI where practical
- `xcrun simctl privacy` to grant, revoke, and reset simulator permission state in scripted scenarios

Service coverage in `simctl privacy` varies by Xcode release; camera, notifications, and tracking have historically not been scriptable. Check the current help output before relying on it.

## Device matrix

Verify on:

- Current supported iOS release
- Minimum supported iOS release
- Physical iPhone
- Simulator where the permission is meaningfully supported

Some behaviors cannot be validated reliably in the simulator.

## Manual scenario template

For each permission, verify:

1. Delete the demo app.
2. Install a clean build.
3. Read status before requesting.
4. Request permission.
5. Grant access.
6. Confirm the returned final state.
7. Change access in Settings.
8. Return to the app.
9. Confirm state refresh.
10. Repeat after denial.
11. Verify restricted behavior where possible.
12. Verify missing configuration in a dedicated test target.

## Special scenarios

Include dedicated coverage for:

- Photos limited access
- Contacts limited access
- Location when-in-use to always upgrade
- Notification provisional authorization
- Notification setting changes
- ATT with system tracking requests disabled
- Camera or microphone hardware unavailability
- Application inactive during request
- Concurrent duplicate requests
- Returning from Settings without changing anything
- Permission changed in Settings while the app is suspended, including capabilities where the system terminates the process

## CI

CI should run:

- Build in Swift 6 mode
- Strict concurrency checking
- Unit tests
- Contract tests
- Documentation build
- Demo-app compilation
- Style lint via `swift format` in strict mode
- Package manifest validation
- Pinned stable Xcode versions for reproducible builds

System-prompt automation through UI-test interruption monitors may run as a non-blocking nightly job. It is inherently flaky and must never gate a release.

Do not pretend CI can fully validate system permission prompts. Verify native permission flows
manually through the demo app on physical devices before release.

## Release test gate

A release candidate is acceptable only when:

- All automated tests pass
- README examples compile
- Every supported permission passes manual device verification
- Minimum and current iOS versions compile
- No concurrency warnings are ignored
- No known continuation leak exists
- No request can silently open Settings
