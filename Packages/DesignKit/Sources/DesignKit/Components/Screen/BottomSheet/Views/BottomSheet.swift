//
//  BottomSheet.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Permukaan bottom sheet: sudut atas membulat, grabber, lalu isi dari pemakai. Tinggi mengikuti isi sampai
/// `maxHeight`; isi yang lebih panjang membuat sheet berhenti di sana dan isinya di-scroll. Geser ke bawah menutup
/// sheet; selama isi di-scroll, hanya dari grabber. Posisi, latar gelap, dan animasi masuk milik
/// `BottomSheetPresenter`. `bottomInset` = safe area bawah, supaya isi tidak tertutup home indicator.
/// TODO: Cocokkan radius, grabber, dan jaraknya dengan Figma; sementara estimasi dari foto.
@MainActor
struct BottomSheet<Content: View>: View {
    @Environment(\.designColors) private var colors
    @Environment(\.accessibilityReduceMotion) private var isReducingMotion
    @GestureState private var dragDistance = CGFloat.zero
    /// Tinggi alami isi, untuk tahu kapan isi melewati `maxHeight` dan perlu di-scroll; nil sebelum terbaca.
    @State private var contentHeight: CGFloat?
    private let closeLabel: String
    private let bottomInset: CGFloat
    private let maxHeight: CGFloat
    private let onClose: () -> Void
    private let content: Content

    /// `closeLabel` = label aksesibilitas grabber, yang bagi VoiceOver menjadi tombol tutup. `maxHeight` = tinggi
    /// seluruh sheet termasuk grabber dan `bottomInset`.
    init(
        closeLabel: String,
        bottomInset: CGFloat,
        maxHeight: CGFloat = .infinity,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.closeLabel = closeLabel
        self.bottomInset = bottomInset
        self.maxHeight = maxHeight
        self.onClose = onClose
        self.content = content()
    }

    var body: some View {
        VStack(spacing: .zero) {
            handle
            contentArea
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, bottomInset)
        .frame(height: isScrolling ? maxHeight : nil, alignment: .top)
        .background(surface)
        // Tinggi isi baru terbaca setelah frame pertama. Sampai itu sheet disembunyikan, supaya tidak tampak naik
        // setinggi isi lalu turun ke batas; tinggi dan visibilitasnya berubah tanpa animasi, sementara sheet tetap
        // meluncur masuk lewat transisi presenter.
        .opacity(contentHeight == nil ? .zero : CustomColors.opaque)
        .transaction { $0.animation = nil }
        .offset(y: dragDistance)
        .animation(releaseAnimation, value: dragDistance == .zero)
        // Isi yang di-scroll memakai geserannya sendiri; di sana hanya grabber yang menutup sheet.
        .gesture(dismissDrag, including: isScrolling ? .subviews : .all)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, onClose)
        .accessibilityIdentifier(ComponentIdentifier.BottomSheet.root)
    }

    private var handle: some View {
        Capsule()
            .fill(colors.colorsOutlineNetral)
            .frame(
                width: CustomSizes.BottomSheet.handleWidth.scaledToArtwork,
                height: CustomSizes.BottomSheet.handleHeight.scaledToArtwork
            )
            .padding(.top, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(dismissDrag)
            .accessibilityElement()
            .accessibilityLabel(closeLabel)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, onClose)
            .accessibilityIdentifier(ComponentIdentifier.BottomSheet.handle)
    }

    /// Isi yang lebih panjang dari sheet di-scroll, tanpa indikator dan tanpa memantul di ujung; isi yang lebih pendek
    /// tetap di atas.
    @ViewBuilder
    private var contentArea: some View {
        if isScrolling {
            ScrollView(.vertical, showsIndicators: false) {
                measuredContent
                    .frame(maxWidth: .infinity)
                    .background(ScrollBounceDisabler())
            }
        } else {
            measuredContent
        }
    }

    /// Selalu setinggi alaminya, supaya tingginya terbaca utuh walau melewati sheet.
    private var measuredContent: some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear { contentHeight = proxy.size.height }
                        .onChange(of: proxy.size.height) { contentHeight = $0 }
                }
            )
    }

    /// Sudut bawah didorong ke luar layar, jadi hanya sudut atas yang tampak membulat.
    private var surface: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(colors.colorsSurfacePrimary)
            .padding(.bottom, -cornerRadius)
    }
}

// MARK: - Helpers

private extension BottomSheet {
    var cornerRadius: CGFloat { CustomSizes.BottomSheet.cornerRadius.scaledToArtwork }

    /// Grabber beserta jarak di atas dan di bawahnya.
    var handleArea: CGFloat {
        CustomSizes.BottomSheet.handleHeight.scaledToArtwork + FigmaSize.spacingMedium.scaledToArtwork
            + FigmaSize.spacingLarge.scaledToArtwork
    }

    /// Ruang isi di bawah `maxHeight`, setelah grabber dan safe area bawah.
    var maxContentHeight: CGFloat { max(.zero, maxHeight - handleArea - bottomInset) }

    /// Isi lebih panjang dari ruang isi: sheet berhenti di `maxHeight` dan isinya di-scroll.
    var isScrolling: Bool { (contentHeight ?? .zero) > maxContentHeight }

    /// Sheet kembali ke tempatnya bila geseran dilepas sebelum jarak tutup.
    var releaseAnimation: Animation? {
        isReducingMotion ? nil : .easeOut(duration: CustomMotion.sheetSlide)
    }

    /// Mengikuti jari hanya ke bawah. Yang dihitung arah lepasnya (`predictedEndTranslation`), jadi sentakan pendek ke
    /// bawah juga menutup. Diukur di koordinat layar: grabber ikut bergeser bersama sheet, jadi di koordinatnya
    /// sendiri jarak geser hampir nol.
    var dismissDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($dragDistance) { value, distance, _ in
                distance = max(.zero, value.translation.height)
            }
            .onEnded { value in
                let distance = CustomSizes.BottomSheet.dismissDistance.scaledToArtwork
                guard value.predictedEndTranslation.height > distance else { return }
                onClose()
            }
    }
}
