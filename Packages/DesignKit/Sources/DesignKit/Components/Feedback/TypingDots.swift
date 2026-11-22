//
//  TypingDots.swift
//  DesignKit
//
//  Created by Wendra on 19/11/26.
//

import SwiftUI

/// Tiga titik yang berdenyut bergiliran dari kiri, tanda jawaban sedang disiapkan. Animasi dijalankan Core Animation
/// lewat opacity (tanpa menggambar ulang per frame) dan hanya hidup selama tampil. Reduce Motion = titik diam terang.
/// Label aksesibilitas dan posisi milik pemakai. TODO: Konfirmasi ukuran, warna, dan durasi dengan Figma.
@MainActor
public struct TypingDots: View {
    @Environment(\.designColors) private var colors
    @Environment(\.accessibilityReduceMotion) private var isReducingMotion
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        HStack(spacing: FigmaSize.spacingSmall.scaledToArtwork) {
            ForEach(CustomMotion.typingDotDelays.indices, id: \.self) { index in
                dot(delay: CustomMotion.typingDotDelays[index])
            }
        }
        // Sel table bisa dipakai ulang: animasi dimulai lagi setiap kali tampil dan berhenti saat hilang.
        .onAppear { isPulsing = !isReducingMotion }
        .onDisappear { isPulsing = false }
        .onChange(of: isReducingMotion) { isPulsing = !$0 }
    }

    private func dot(delay: TimeInterval) -> some View {
        Circle()
            .fill(colors.colorsTextSecondary)
            .frame(width: dotSize, height: dotSize)
            .opacity(opacity)
            .animation(pulse(delay: delay), value: isPulsing)
    }
}

// MARK: - Helpers

private extension TypingDots {
    var dotSize: CGFloat { CustomSizes.TypingDots.dot.scaledToArtwork }

    /// Diam = terang supaya tetap terlihat; berdenyut = mulai redup lalu bolak-balik ke terang.
    var opacity: Double {
        guard isPulsing else { return CustomColors.opaque }
        return CustomColors.TypingDots.dimmedOpacity
    }

    func pulse(delay: TimeInterval) -> Animation? {
        guard isPulsing else { return nil }
        return .easeInOut(duration: CustomMotion.typingDotPulse).repeatForever(autoreverses: true).delay(delay)
    }
}
