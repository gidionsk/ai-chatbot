//
//  MessageComposerAttachment.swift
//  DesignKit
//
//  Created by Wendra on 10/11/26.
//

/// Tombol lampiran di kiri composer. Nil = tombol tidak tampil; pemakai yang menentukan kapan tersedia dan
/// apa yang terjadi saat diketuk.
public struct MessageComposerAttachment {
    /// Label aksesibilitas tombol.
    let label: String
    let onTap: () -> Void

    public init(label: String, onTap: @escaping () -> Void) {
        self.label = label
        self.onTap = onTap
    }
}
