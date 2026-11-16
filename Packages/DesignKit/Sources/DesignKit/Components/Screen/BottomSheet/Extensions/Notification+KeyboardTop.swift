//
//  Notification+KeyboardTop.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import UIKit

extension Notification {
    /// Tepi atas keyboard setelah animasinya selesai, di koordinat layar; saat keyboard menutup nilainya tepi bawah
    /// layar. Nil bila notifikasi tidak membawa frame keyboard.
    var keyboardTop: CGFloat? {
        (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.minY
    }
}
