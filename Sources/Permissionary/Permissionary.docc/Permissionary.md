# ``Permissionary``

A SwiftUI-first permissions library for iOS, built on Swift 6 strict concurrency.

## Overview

Permissionary puts nine iOS capabilities behind one consistent surface: read status without
side effects, request with async/await, observe changes as streams, and recover explicitly.

Reading status never presents a prompt. Denied, restricted, and limited outcomes are states,
not errors; requests throw only for exceptional conditions such as a missing usage
description, reported before the system would terminate the process. Duplicate requests for
one capability coalesce into a single native prompt with one shared result, and prompts for
different capabilities appear one at a time instead of stacking.

Inject ``PermissionsClient`` through the SwiftUI environment as `\.permissions`, observe a
capability through its `@Observable` model, and present the system's limited photo-library
picker with the `limitedPhotoLibraryPicker(isPresented:)` view modifier.

## Topics

### Client

- ``PermissionsClient``

### Capabilities

- ``CameraPermission``
- ``MicrophonePermission``
- ``PhotosReadWritePermission``
- ``PhotosAddOnlyPermission``
- ``ContactsPermission``
- ``LocationWhenInUsePermission``
- ``LocationAlwaysPermission``
- ``NotificationsPermission``
- ``TrackingPermission``

### Statuses

- ``PermissionStatus``
- ``PermissionAuthorization``
- ``CameraStatus``
- ``MicrophoneStatus``
- ``PhotosReadWriteStatus``
- ``PhotosAddOnlyStatus``
- ``ContactsStatus``
- ``LocationWhenInUseStatus``
- ``LocationAlwaysStatus``
- ``NotificationsStatus``
- ``TrackingStatus``

### Status Details

- ``LocationAccuracy``
- ``NotificationGrant``
- ``NotificationOptions``
- ``NotificationSettings``
- ``NotificationSetting``
- ``NotificationAlertStyle``

### Recovery

- ``PermissionRecovery``

### Errors and Diagnostics

- ``PermissionError``
- ``PermissionsDiagnostics``
- ``UsageDescriptionKey``

### SwiftUI Models

- ``CameraPermissionModel``
- ``MicrophonePermissionModel``
- ``PhotosReadWritePermissionModel``
- ``PhotosAddOnlyPermissionModel``
- ``ContactsPermissionModel``
- ``LocationWhenInUsePermissionModel``
- ``LocationAlwaysPermissionModel``
- ``NotificationsPermissionModel``
- ``TrackingPermissionModel``
