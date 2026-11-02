//
//  View+ScrollProgress.swift
//  DesignKit
//
//  Created by Wendra on 16/10/26.
//

import SwiftUI

public extension View {
    /// Apply to the scroll content, after its padding. Name the containing ScrollView with the same space.
    /// Melaporkan seberapa jauh konten digulir dari posisi teratas: 0 di atas (termasuk tarikan bounce),
    /// naik sebanding offset, dan berhenti di 1 setelah `distance`. Offset di bawah `threshold` dianggap masih
    /// di atas. Nilai awal dilaporkan, lalu hanya perubahan: setelah melewati `distance` tidak ada laporan lagi,
    /// jadi scroll panjang tidak me-render ulang pemakai. Each observer is independent.
    @MainActor
    func onScrollProgressChange<Space: Hashable>(
        in coordinateSpace: Space, distance: CGFloat, threshold: CGFloat = LayoutTolerance.measurement,
        perform: @escaping (CGFloat) -> Void
    ) -> some View {
        background {
            GeometryReader { geometry in
                let offset = -geometry.frame(in: .named(coordinateSpace)).minY
                // Jarak minimal setengah point agar pembagian aman walau caller memberi nol.
                let span = max(distance, LayoutTolerance.measurement)
                let progress = offset < max(.zero, threshold) ? .zero : min(offset, span) / span
                Color.clear
                    .onAppear { perform(progress) }
                    .onChange(of: progress, perform: perform)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
