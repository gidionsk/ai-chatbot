//
//  MessageComposerAction.swift
//  DesignKit
//
//  Created by Wendra on 30/10/26.
//

/// Isi tombol di kanan composer. Caller menentukan fase; composer hanya menampilkan dan meneruskan tap.
public enum MessageComposerAction: Equatable, Sendable {
    /// Panah kirim; aktif bila draft berisi.
    case send
    /// Ikon stop yang bisa ditekan; input tetap bisa diketik untuk pertanyaan berikutnya.
    case stop
    /// Stop sudah ditekan dan sedang diproses; ikon stop nonaktif.
    case stopping
}
