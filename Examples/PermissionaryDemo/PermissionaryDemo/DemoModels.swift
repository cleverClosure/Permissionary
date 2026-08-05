//
//  DemoModels.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import Permissionary

@MainActor
final class DemoModels {
    let camera: CameraPermissionModel
    let microphone: MicrophonePermissionModel
    let photosReadWrite: PhotosReadWritePermissionModel
    let photosAddOnly: PhotosAddOnlyPermissionModel
    let contacts: ContactsPermissionModel
    let locationWhenInUse: LocationWhenInUsePermissionModel
    let locationAlways: LocationAlwaysPermissionModel
    let notifications: NotificationsPermissionModel
    let tracking: TrackingPermissionModel

    init(client: PermissionsClient) {
        camera = CameraPermissionModel(permission: client.camera)
        microphone = MicrophonePermissionModel(permission: client.microphone)
        photosReadWrite = PhotosReadWritePermissionModel(permission: client.photosReadWrite)
        photosAddOnly = PhotosAddOnlyPermissionModel(permission: client.photosAddOnly)
        contacts = ContactsPermissionModel(permission: client.contacts)
        locationWhenInUse = LocationWhenInUsePermissionModel(permission: client.locationWhenInUse)
        locationAlways = LocationAlwaysPermissionModel(permission: client.locationAlways)
        notifications = NotificationsPermissionModel(permission: client.notifications)
        tracking = TrackingPermissionModel(permission: client.tracking)
    }
}
