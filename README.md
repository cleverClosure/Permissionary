![Permissionary — SwiftUI-first permissions for iOS](Assets/permissionary-readme-header.png)

# Permissionary

A SwiftUI-first permissions library for iOS, built on Swift 6 strict concurrency.

Nine capabilities behind one consistent surface: read status without side effects, request with
async/await, observe changes as streams, and recover explicitly.

## Design rules

- `status()` never presents a system prompt. It is safe to call from anywhere, at any time.
- Denied, restricted, and limited outcomes are states, not errors. `request()` throws only for
  exceptional conditions — most importantly a missing usage description, reported as a
  descriptive error before the system would terminate the process.
- Every capability exposes a typed status with framework detail (location accuracy,
  notification grant and channel settings) alongside a normalized `PermissionAuthorization`
  for generic UI.
- Recovery is explicit and application-controlled. Statuses suggest `openSettings` or
  `manageLimitedSelection`; the library never opens Settings on its own.
- Concurrent requests are coordinated: duplicate requests for one capability coalesce into a
  single native prompt with one shared result, and prompts for different capabilities appear
  one at a time instead of stacking.
- The client is a struct of replaceable operations. Tests and previews inject deterministic
  fakes without a global singleton.

## Requirements

- iOS 18+
- Swift 6
- Swift Package Manager

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/cleverClosure/Permissionary.git", exact: "0.1.0")
]
```

Until 1.0, minor releases may contain breaking changes, so pin an exact version.

## Capabilities

| Capability | Accessor | Status type |
|---|---|---|
| Camera | `camera` | `CameraStatus` |
| Microphone | `microphone` | `MicrophoneStatus` |
| Photos read/write | `photosReadWrite` | `PhotosReadWriteStatus` |
| Photos add-only | `photosAddOnly` | `PhotosAddOnlyStatus` |
| Contacts | `contacts` | `ContactsStatus` |
| Location when in use | `locationWhenInUse` | `LocationWhenInUseStatus` |
| Location always | `locationAlways` | `LocationAlwaysStatus` |
| Notifications | `notifications` | `NotificationsStatus` |
| Tracking | `tracking` | `TrackingStatus` |

The client also exposes `openSettings` and `openNotificationSettings`, which open the
application's page and its notification settings in the Settings app.

## Usage-description keys

Requests validate configuration first and throw a descriptive `PermissionError` instead of
letting the system terminate the process. `UsageDescriptionKey` provides the keys as
constants, and a debug-build check surfaces every problem at once — each issue is exactly
the error the corresponding request would throw:

```swift
func auditPermissionConfiguration() {
    for issue in PermissionsDiagnostics.configurationIssues() {
        print(issue)
    }
}
```

| Capability | Required Info.plist key |
|---|---|
| Camera | `NSCameraUsageDescription` |
| Microphone | `NSMicrophoneUsageDescription` |
| Photos read/write | `NSPhotoLibraryUsageDescription` |
| Photos add-only | `NSPhotoLibraryAddUsageDescription` |
| Contacts | `NSContactsUsageDescription` |
| Location when in use | `NSLocationWhenInUseUsageDescription` |
| Location always | `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysAndWhenInUseUsageDescription` |
| Tracking | `NSUserTrackingUsageDescription` |
| Notifications | none |

## Quick start

```swift
func enableCamera(permissions: PermissionsClient) async throws {
    let status = await permissions.camera.status()
    guard status.authorization == .notDetermined else {
        return
    }

    let result = try await permissions.camera.request()
    if result.recovery == .openSettings {
        await permissions.openSettings()
    }
}
```

A denied request returns a status whose `recovery` tells you what the application can offer
next. Opening Settings remains your decision, made after your own explanation UI.

## SwiftUI

Inject the client through the environment and observe a capability with its model:

```swift
struct CameraStatusView: View {
    @Environment(\.permissions) private var permissions
    @State private var model: CameraPermissionModel?

    var body: some View {
        VStack {
            Text(model?.status.map { String(describing: $0.authorization) } ?? "loading")
            Button("Enable Camera") {
                Task {
                    _ = try? await model?.request()
                }
            }
        }
        .task {
            if model == nil {
                model = CameraPermissionModel(permission: permissions.camera)
            }
        }
    }
}
```

`\.permissions` defaults to the live client, which is safe because status reads never prompt;
previews and tests inject fakes. Each model reads the initial status, follows the capability's
update stream, and exposes explicit `refresh()` and `request()` operations. The live client
re-reads every capability when the application becomes active, so models reflect Settings
changes without any per-view code. Requests are never triggered by view lifecycle.

When photo access is limited, present the system selection manager with the
`limitedPhotoLibraryPicker(isPresented:)` modifier; contacts use the system's native
`contactAccessPicker`.

## Observing changes

Every capability publishes a status stream. Streams never block a slow consumer; they always
deliver the latest snapshot.

```swift
func observeCamera(permissions: PermissionsClient) async {
    for await status in await permissions.camera.updates() {
        print(status.authorization)
    }
}
```

## Notification options

Notifications accept per-request options; the parameterless form requests `.standard`
(alert, sound, and badge).

```swift
func requestQuietNotifications(permissions: PermissionsClient) async throws {
    let result = try await permissions.notifications.request([.alert, .sound, .provisional])
    if result.grant == .provisional {
        print("Delivering quietly until the user promotes them.")
    }
}
```

## Testing your app

Every operation on the client is a value, so a test overrides exactly what it needs:

```swift
func makeStubClient() -> PermissionsClient {
    var permissions = PermissionsClient.live
    permissions.camera = CameraPermission(
        status: { CameraStatus(authorization: .authorized, recovery: nil) },
        request: { CameraStatus(authorization: .authorized, recovery: nil) },
        updates: { AsyncStream { $0.finish() } }
    )
    return permissions
}
```

For fully hermetic tests, construct the whole client from stubs through
`PermissionsClient.init` instead of starting from `.live`.

## Demo app

`Examples/PermissionaryDemo` drives all nine capabilities through the library's models and
environment injection, including a coordination lab for coalescing and prompt serialization.
It is also the harness for manual verification on physical devices.

## Privacy

The library collects no data, tracks nothing, and uses no required-reason APIs. It ships a
privacy manifest (`PrivacyInfo.xcprivacy`) declaring exactly that.

## Documentation

- [Project scope](Docs/PROJECT.md)
- [API design](Docs/API.md)
- [Permission matrix](Docs/PERMISSION_MATRIX.md)
- [Architecture](Docs/ARCHITECTURE.md)
- [Testing strategy](Docs/TESTING.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## Project status

All nine capabilities are implemented, with a layered automated suite (mapping, contract,
coordination, and SwiftUI tests) plus manual device verification. The public API is not yet
stable: before 1.0, breaking changes may occur in any minor release.

Code examples in this README are compiled as part of the test suite, so they cannot drift
from the actual API.

## License

MIT. See [LICENSE](LICENSE).
