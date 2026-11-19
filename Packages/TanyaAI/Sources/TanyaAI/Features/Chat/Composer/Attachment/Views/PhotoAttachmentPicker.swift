//
//  PhotoAttachmentPicker.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import PhotosUI
import SwiftUI

/// Galeri foto sistem (`PHPicker`, tanpa izin akses galeri) untuk satu gambar lampiran. Representasi asli dipakai
/// (`.current`), jadi foto HEIC tidak diubah menjadi JPEG.
@MainActor
struct PhotoAttachmentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    /// Foto berformat selain HEIC, JPG/JPEG, atau PNG.
    let onReject: () -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> PhotoAttachmentPickerCoordinator {
        PhotoAttachmentPickerCoordinator(onPick: onPick, onReject: onReject, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}
}
