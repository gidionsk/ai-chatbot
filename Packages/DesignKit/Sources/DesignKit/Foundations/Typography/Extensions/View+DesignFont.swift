//
//  View+DesignFont.swift
//  DesignKit
//
//  Created by Wendra on 14/11/26.
//

import SwiftUI

public extension View {
    /// Font sesuai peran teks DesignKit; lihat `DesignFontRole`.
    func designFont(_ role: DesignFontRole) -> some View {
        font(role.font)
    }
}
