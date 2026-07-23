//
//  LimitedLibraryPicker.swift
//  PermissionaryDemo
//
//  Created by Tim Isaev
//

import PhotosUI
import UIKit

@MainActor
enum LimitedLibraryPicker {
    static func present() {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        guard let root = windows.first(where: \.isKeyWindow)?.rootViewController else {
            return
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: top)
    }
}
