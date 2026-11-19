//
//  DocumentAttachmentPickerCoordinator.swift
//  TanyaAI
//
//  Created by Wendra on 18/11/26.
//

import UIKit

/// Delegate aplikasi Files: meneruskan file pertama, lalu menutup sheet pembungkusnya. Class karena delegate UIKit
/// harus `NSObject`.
final class DocumentAttachmentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void
    private let onDismiss: () -> Void

    init(onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onPick = onPick
        self.onDismiss = onDismiss
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onDismiss()
        guard let url = urls.first else { return }
        onPick(url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDismiss()
    }
}
