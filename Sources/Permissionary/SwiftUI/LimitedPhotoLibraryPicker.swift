//
//  LimitedPhotoLibraryPicker.swift
//  Permissionary
//
//  Created by Tim Isaev
//

import PhotosUI
import SwiftUI

extension View {
    /// Presents the system picker for managing the limited photo-library
    /// selection when the binding becomes true.
    ///
    /// Attach this where a ``PhotosReadWriteStatus`` reports
    /// ``PermissionRecovery/manageLimitedSelection`` and set the binding
    /// only from an explicit user action. The binding returns to false
    /// when the user dismisses the picker. Contact selection management
    /// needs no equivalent because the system provides a native SwiftUI
    /// entry point.
    ///
    /// - Parameter isPresented: Controls the picker's presentation.
    /// - Returns: A view that presents the picker over this view.
    public func limitedPhotoLibraryPicker(isPresented: Binding<Bool>) -> some View {
        background(LimitedPhotoLibraryPickerPresenter(isPresented: isPresented))
    }
}

private struct LimitedPhotoLibraryPickerPresenter: UIViewControllerRepresentable {
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ controller: UIViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.dismiss = { isPresented = false }
        guard isPresented, !coordinator.isPresenting else {
            return
        }
        coordinator.isPresenting = true
        PHPhotoLibrary.shared()
            .presentLimitedLibraryPicker(from: controller) { _ in
                Task { @MainActor in
                    coordinator.pickerDidDismiss()
                }
            }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        var isPresenting = false
        var dismiss: (() -> Void)?

        func pickerDidDismiss() {
            isPresenting = false
            dismiss?()
        }
    }
}
