//
//  ScrollBounceDisabler.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Pasang sebagai `background` isi `ScrollView`: scroll view itu tidak lagi memantul di ujung. iOS 15 belum punya API
/// SwiftUI untuk ini (`scrollBounceBehavior` baru iOS 16.4, dan itu pun tetap memantul saat isi bisa di-scroll). Bila
/// scroll view di atasnya tidak ditemukan, tidak ada yang berubah.
struct ScrollBounceDisabler: UIViewRepresentable {
    func makeUIView(context: Context) -> BounceDisablingView {
        let view = BounceDisablingView()
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        return view
    }

    func updateUIView(_ view: BounceDisablingView, context: Context) {}
}
