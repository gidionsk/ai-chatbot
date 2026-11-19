//
//  PhotoAttachmentPickerCoordinator.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import PhotosUI
import UniformTypeIdentifiers

/// Delegate galeri: memuat file gambar yang didukung, menyalinnya sebelum file sementara sistem dihapus, lalu
/// meneruskannya di main queue. Galeri sistem tidak bisa memfilter per format, jadi foto berformat lain (mis. GIF,
/// WebP) dilaporkan lewat `onReject` (keputusan user). Class karena delegate UIKit harus `NSObject`.
/// TODO: Gagal memuat file (jarang, mis. foto iCloud tanpa koneksi) belum punya desain; sementara diabaikan.
final class PhotoAttachmentPickerCoordinator: NSObject, PHPickerViewControllerDelegate {
    private let onPick: (URL) -> Void
    private let onReject: () -> Void
    private let onDismiss: () -> Void

    init(onPick: @escaping (URL) -> Void, onReject: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.onPick = onPick
        self.onReject = onReject
        self.onDismiss = onDismiss
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        onDismiss()
        guard let provider = results.first?.itemProvider else { return }
        guard let type = UTType.chatAttachmentImage(in: provider.registeredTypeIdentifiers) else {
            return onReject()
        }
        provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { [onPick] url, _ in
            let copy = url.flatMap { try? FileManager.default.copyChatAttachment(from: $0) }
            DispatchQueue.main.async {
                guard let copy else { return }
                onPick(copy)
            }
        }
    }
}
