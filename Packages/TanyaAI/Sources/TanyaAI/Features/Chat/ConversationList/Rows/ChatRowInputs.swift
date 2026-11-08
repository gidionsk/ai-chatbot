//
//  ChatRowInputs.swift
//  TanyaAI
//
//  Created by Wendra on 6/11/26.
//

import DesignKit
import Foundation
import SwiftUI

/// Nilai yang dibaca baris tetapi tidak tersimpan di `ChatListItem`. Sel yang tampil tidak mengikuti update SwiftUI,
/// jadi saat salah satunya berubah semua baris dibangun ulang. Palette dibandingkan lewat tipenya karena tiap tema
/// adalah tipe tersendiri dan `FigmaColorProtocol` tidak `Equatable`.
struct ChatRowInputs: Equatable {
    private let welcome: WelcomeContent?
    private let locale: Locale
    private let paletteID: ObjectIdentifier

    init(
        welcome: WelcomeContent? = nil, locale: Locale = .current,
        colors: any FigmaColorProtocol = EnvironmentValues().designColors
    ) {
        self.welcome = welcome
        self.locale = locale
        paletteID = ObjectIdentifier(type(of: colors))
    }
}
