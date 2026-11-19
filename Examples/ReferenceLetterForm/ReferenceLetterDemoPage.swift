//
//  ReferenceLetterDemoPage.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import DesignKit
import SwiftUI

/// Halaman lokal opsional untuk melihat form tanpa menunggu pesan agen atau memanggil service.
@MainActor
struct ReferenceLetterDemoPage: View {
    @State private var demo = ReferenceLetterDemoState()

    var body: some View {
        ScrollView {
            ReferenceLetterDemoForm()
                .padding(FigmaSize.spacingLarge.scaledToArtwork)
        }
        .environmentObject(demo)
        .modifier(ReferenceLetterDemoSheetPresenter(demo: demo))
    }
}
