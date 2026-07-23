# Device Verification Checklist

This is the manual release gate from [TESTING.md](TESTING.md). Automated suites prove the
library's coordination and mapping logic against scripted shims; this checklist proves the thin
native shims and the system behaviors that automation cannot reach: real prompts, Settings
round-trips, process termination, and one-per-install upgrade flows.

Run it with the demo app in `Examples/PermissionaryDemo` on a physical iPhone. A release
candidate needs a pass on the current iOS release and the minimum supported release (iOS 18).

## Run record

| Field | Value |
|---|---|
| Device | |
| iOS version | |
| Commit | |
| Date | |
| Result | |

## Preparation

- Open `Examples/PermissionaryDemo/PermissionaryDemo.xcodeproj`, select your development team
  under Signing & Capabilities, and run on the device. Do not commit the team change.
- Deleting the app resets its permission state, except one-per-install flows (the Always
  upgrade prompt and tracking) which may need Settings > General > Transfer or Reset iPhone >
  Reset > Reset Location & Privacy. That reset affects every app on the device.
- Every capability section below assumes a fresh install unless a step says otherwise.
- The app's Settings page is reachable via Settings > Apps > PermissionaryDemo.

## Global

- [ ] Fresh install: every list row shows `notDetermined` and no prompt appears at launch.
- [ ] Opening every capability screen presents no prompt: status reads never request.
- [ ] Every Configuration row shows a green check: all usage keys ship in the demo Info.plist.
- [ ] Activation refresh: with notifications granted, disable Sounds in Settings >
      Notifications > PermissionaryDemo, return to the app without relaunching. The settings
      snapshot updates. The demo contains no scene-phase code; the live client republishes on
      activation.
- [ ] Terminating Settings change: toggle camera access while the app is suspended. The system
      terminates the app; on relaunch the list shows the new state.

## Camera

- [ ] Request, allow: `authorized`, recovery `none`.
- [ ] Reset, request, deny: `denied`, recovery `openSettings`; denial is a status, not an error.
- [ ] Request again after denial: no prompt, same status returned immediately.
- [ ] Open Settings lands on the app's page; re-enable, relaunch after termination, `authorized`.

## Microphone

- [ ] Request, allow: `authorized`.
- [ ] Reset, request, deny: `denied` with `openSettings`; repeat request shows no prompt.
- [ ] Toggle in Settings terminates the suspended app; relaunch shows the toggled state.

## Photos Read/Write

- [ ] Request, Limit Access: `limited`, recovery `manageLimitedSelection`.
- [ ] Manage Limited Selection presents the system picker; changing the selection keeps
      `limited` after refresh.
- [ ] Reset, request, Allow Full Access: `authorized`.
- [ ] Reset, request, deny: `denied` with `openSettings`.
- [ ] Photos Add Only stays `notDetermined` throughout: the two capabilities are independent.

## Photos Add Only

- [ ] Request, allow: `authorized` while Read/Write reports its own state unchanged.
- [ ] Reset, request, deny: `denied` with `openSettings`.

## Contacts

- [ ] Request, Select Contacts (limited): `limited`, recovery `manageLimitedSelection`; the
      manage button presents the contact access picker.
- [ ] Reset, request, Allow Full Access: `authorized`.
- [ ] Reset, request, deny: `denied` with `openSettings`.
- [ ] Toggle in Settings terminates the suspended app; relaunch shows the new state.

## Location When In Use

- [ ] Request, Allow While Using: `authorized`, accuracy `full`.
- [ ] Allow Once: `authorized` for this session; after a later cold launch the status returns
      to `notDetermined`.
- [ ] Precise Location off in Settings: accuracy `reduced` while still `authorized`.
- [ ] Reset, request, deny: `denied` with `openSettings`.
- [ ] Settings > Privacy & Security > Location Services master switch off: `denied`.
- [ ] Location Always screen shows a when-in-use grant as `limited`.

## Location Always

- [ ] With when-in-use granted, request Always: the call returns promptly with the current
      snapshot; it never hangs waiting for the upgrade prompt.
- [ ] Accept the upgrade prompt when it appears: status becomes `authorized` on a later read
      or through the update stream.
- [ ] Request again after the one-per-install prompt was used: no prompt, immediate return.
- [ ] Grant Always directly in Settings: both location screens show `authorized`.
- [ ] Provisional window: if the system reports Always before the user confirmed, note that
      the status may downgrade later without any app action.

## Notifications

- [ ] Request with alert, sound, badge: prompt appears; allow: `authorized`, grant `standard`,
      channels enabled in the snapshot.
- [ ] Reset, request, deny: `denied` with `openSettings`.
- [ ] Reset, request with only Provisional on: no prompt, `limited`, grant `provisional`;
      notifications deliver quietly.
- [ ] Toggle individual channels in Settings and return: snapshot reflects the change without
      relaunch; the app is not terminated.
- [ ] Open Notification Settings lands directly on the app's notification settings page.

## Tracking

- [ ] Settings > Privacy & Security > Tracking > Allow Apps to Request to Track on: request
      shows the prompt; allow: `authorized`, deny: `denied`.
- [ ] Fresh install with the system switch off: request shows no prompt; record the reported
      status (the library reports the system truth).
- [ ] Request only while the app is active; backgrounding during a request is the documented
      failure mode for the prompt not appearing.

## Coordination lab

- [ ] Request camera twice: exactly one prompt; both callers report the same final status.
- [ ] Request camera and microphone: two prompts appear strictly one after the other, never
      stacked; each returns its own status.

## Sign-off

All boxes checked on both iOS versions, or every unchecked box has a linked issue. Attach this
completed checklist to the release notes for the tagged version.
