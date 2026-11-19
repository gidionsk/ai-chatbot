//
//  DocumentAttachmentPicker.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import SwiftUI
import UniformTypeIdentifiers

/// Aplikasi Files untuk satu PDF atau gambar lampiran. `asCopy` = sistem menyalin file ke folder aplikasi, jadi tidak
/// perlu akses security-scoped.
@MainActor
struct DocumentAttachmentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onDismiss: () -> Void

    func makeCoordinator() -> DocumentAttachmentPickerCoordinator {
        DocumentAttachmentPickerCoordinator(onPick: onPick, onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: UTType.chatAttachments, asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
}
