//
//  ChatRowActions.swift
//  TanyaAI
//
//  Created by Wendra on 6/11/26.
//

import Foundation

/// Aksi dari dalam baris. Sel yang tampil memegang closure dari saat sel dibuat, jadi baris menerima penerus dari
/// `ChatTableController` yang selalu memanggil aksi terbaru, tanpa membangun ulang sel.
struct ChatRowActions {
    var onOpenLink: (URL) -> Void = { _ in }
    var onSelectShortcut: (WelcomeShortcut) -> Void = { _ in }
    var onSelectFollowUp: (String) -> Void = { _ in }
}
