# Permission Matrix

This document is the behavioral source of truth for every supported permission.

Complete each section before implementing its adapter.

## Shared questions

For every capability, document:

- Apple framework and API
- Required Info.plist keys
- Required entitlements
- Native states
- Library state mapping
- Whether a system prompt can appear
- Repeat-request behavior
- Settings or limited-selection recovery
- Actor and lifecycle constraints
- Whether a Settings change terminates a suspended app
- How Screen Time or MDM restrictions surface
- Simulator limitations
- Real-device test scenarios
- Behavior for unknown future states

## Summary

| Capability | Framework | Required configuration | Important states | Recovery |
|---|---|---|---|---|
| Camera | AVFoundation | Camera usage description | Not determined, authorized, denied, restricted | Settings |
| Location: When In Use | CoreLocation | Location usage description | Not determined, when-in-use, always, denied, restricted | Settings |
| Location: Always | CoreLocation | Location usage descriptions | When-in-use, always, denied, restricted | Settings |
| Notifications | UserNotifications | Request options | Not determined, denied, authorized, provisional, ephemeral | Settings |
| Photos: Read/Write | Photos | Photo-library usage description | Not determined, limited, authorized, denied, restricted | Settings or limited selection |
| Photos: Add Only | Photos | Add-to-library usage description | Not determined, authorized, denied, restricted | Settings |
| Contacts | Contacts | Contacts usage description | Not determined, limited, authorized, denied, restricted | Settings |
| Microphone | AVFAudio | Microphone usage description | Undetermined, granted, denied | Settings |
| Tracking | AppTrackingTransparency | Tracking usage description | Not determined, authorized, denied, restricted | Settings may be limited |

The exact native states and configuration requirements must be verified against the deployment SDK during implementation.

---

## Camera

### Framework

`AVFoundation`

### Configuration

- Camera usage-description key

### Native states

- Not determined
- Authorized
- Denied
- Restricted
- Unknown future value

### Request rules

- A system prompt may appear only when state is not determined
- Repeated requests after denial do not show another system prompt

### Recovery

- Denied: application may offer Open Settings
- Restricted: Settings may not resolve the restriction

### Settings change behavior

Changing camera access in Settings is expected to terminate a suspended app. Verify on device and document the relaunch flow.

### Test scenarios

- Clean install
- Grant
- Deny
- Repeat request after denial
- Change in Settings
- Return to foreground
- Device without usable camera
- Unknown-state mapping

---

## Location: When In Use

### Framework

`CoreLocation`

### Configuration

- When-in-use location usage-description key

### Native states

- Not determined
- Authorized when in use
- Authorized always
- Denied
- Restricted
- Unknown future value

### Typed details

Details include accuracy authorization (full or reduced) alongside the authorization status.

### Request rules

- First request may show a system prompt
- Already-authorized-always satisfies when-in-use access
- Repeated requests after denial do not show another system prompt

### Recovery

- Denied: application may offer Open Settings
- Restricted: recovery may not be possible

### Lifecycle concerns

- Delegate callbacks
- Manager lifetime
- Main-thread or actor isolation
- Status refresh after returning from Settings
- Authorization changes are expected to arrive through the delegate without terminating the app; verify on device

### Test scenarios

- Clean install
- Grant while in use
- Grant always where applicable
- Deny
- Repeat request
- Change in Settings
- Restricted state
- Approximate location (reduced accuracy) grant

---

## Location: Always

### Framework

`CoreLocation`

### Configuration

- Required location usage-description keys
- Any additional platform configuration required by the target SDK

### Native states

- Not determined
- Authorized when in use
- Authorized always
- Denied
- Restricted
- Unknown future value

### Typed details

Details include accuracy authorization (full or reduced) alongside the authorization status.

### Library state mapping

A when-in-use grant is normalized as `limited` for this capability (ADR 0007).

### Request rules

Always authorization is an upgrade flow, not an independent Boolean permission.

The implementation must define:

- Required prior state
- Whether an intermediate when-in-use request is performed
- Whether the library performs one step or exposes separate steps
- Behavior when the system defers or changes the prompt

### Provisional Always

Requesting Always from not determined can report authorized-always while the user has only granted when-in-use access. The system may show the real upgrade prompt later, at a time it chooses, and no public API distinguishes the provisional window.

The library reports the system status truthfully and documents this behavior (ADR 0007). The status may downgrade later without any app action.

### Recovery

- Denied: application may offer Open Settings
- Authorized when in use: may require an explicit upgrade action
- Restricted: recovery may not be possible

### Test scenarios

- Clean install
- Upgrade from when in use
- Direct call while not determined
- Denial
- Repeated upgrade request
- Change in Settings
- Background-location capability variations

---

## Notifications

### Framework

`UserNotifications`

### Configuration

The application chooses authorization options, such as:

- Alert
- Sound
- Badge
- Other modern options supported by the target SDK

### Native states

- Not determined
- Denied
- Authorized
- Provisional
- Ephemeral
- Unknown future value

### Request rules

- Request options are part of the permission semantics
- The final state must be read after the request completes
- A successful request call does not necessarily mean fully authorized

### Recovery

- Denied: application may offer Open Settings
- Authorized variants: application may inspect detailed notification settings

### API decisions

- Request options are a per-request parameter with a default of alert, sound, and badge (ADR 0008)
- Provisional authorization is normalized as `limited`; ephemeral as `authorized`; typed details preserve the exact state
- The status includes a Sendable copy of detailed notification settings; the native settings object is not Sendable and is never exposed

### Settings change behavior

Notification setting changes do not terminate the app. Status must be re-read when the app becomes active.

### Test scenarios

- Standard authorization
- Denial
- Provisional authorization
- Repeat request
- Change individual settings
- Return to foreground
- Simulator and physical-device differences

---

## Photos: Read/Write

### Framework

`Photos`

### Configuration

- Photo-library usage-description key

### Native states

- Not determined
- Limited
- Authorized
- Denied
- Restricted
- Unknown future value

### Request rules

- Limited access is a valid successful state
- The library must not normalize limited access to fully authorized
- Request behavior depends on the selected access level

### Recovery

- Denied: application may offer Open Settings
- Limited: application may offer limited-selection management where supported

### Settings change behavior

Changing photo library access in Settings is expected to terminate a suspended app. Verify on device, including changes to the limited selection.

### Test scenarios

- Full access
- Limited access
- Change limited selection
- Denial
- Repeat request
- Change in Settings
- Empty limited selection
- Unknown-state mapping

---

## Photos: Add Only

### Framework

`Photos`

### Configuration

- Add-to-photo-library usage-description key

### Native states

- Not determined
- Authorized
- Denied
- Restricted
- Unknown future value

### Request rules

Add-only access must remain distinct from read/write access.

### Recovery

- Denied: application may offer Open Settings
- Restricted: recovery may not be possible

### Settings change behavior

Changing add-only access in Settings is expected to terminate a suspended app. Verify on device.

### Test scenarios

- Grant
- Deny
- Repeat request
- Compare with read/write authorization
- Change in Settings

---

## Contacts

### Framework

`Contacts`

### Configuration

- Contacts usage-description key

### Native states

Verify against the deployment SDK, including any modern limited-access state.

Expected categories:

- Not determined
- Limited
- Authorized
- Denied
- Restricted
- Unknown future value

### Request rules

- Limited access must be preserved if supported
- The final state must be read after the request

### Recovery

- Denied: application may offer Open Settings
- Limited: expose any supported selection-management flow

### Settings change behavior

Changing contacts access in Settings is expected to terminate a suspended app. Verify on device.

### Test scenarios

- Full access
- Limited access
- Denial
- Repeat request
- Change selected contacts
- Change in Settings
- Empty contact set

---

## Microphone

### Framework

Use the current non-deprecated API available in the deployment SDK.

### Configuration

- Microphone usage-description key

### Native states

- Undetermined
- Granted
- Denied
- Unknown future value

### Request rules

- A system prompt may appear only from the undetermined state
- Repeated requests after denial do not show another system prompt

### Recovery

- Denied: application may offer Open Settings

### Restrictions

The modern audio permission API exposes no restricted state. Verify how Screen Time or MDM microphone restrictions surface through it.

### Settings change behavior

Changing microphone access in Settings is expected to terminate a suspended app. Verify on device.

### Test scenarios

- Grant
- Deny
- Repeat request
- Change in Settings
- Audio route or hardware variations where relevant

---

## App Tracking Transparency

### Framework

`AppTrackingTransparency`

### Configuration

- Tracking usage-description key
- Any application-level prerequisites required by Apple policy

### Native states

- Not determined
- Restricted
- Denied
- Authorized
- Unknown future value

### Request rules

The adapter must define:

- Required application-active state
- Behavior when system-level tracking requests are disabled
- Repeated request behavior
- Whether the prompt can appear in the current lifecycle state

### Recovery

Do not assume Settings can always resolve restricted or denied states.

### Settings change behavior

Verify on device whether toggling per-app tracking in Settings terminates a suspended app.

### Test scenarios

- Authorization allowed
- Authorization denied
- System-level tracking requests disabled
- Restricted state
- Repeated request
- App inactive during request attempt
- Change in Settings

---

## Unknown future states

Every Apple enum mapping must include an unknown-default branch.

The library should:

- Avoid crashing
- Preserve forward compatibility
- Return a safe normalized state
- Make the unexpected native value diagnosable in debug builds
- Avoid exposing unstable raw values as the only public representation
