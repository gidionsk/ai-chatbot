//
//  BottomSheet.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

/// Permukaan bottom sheet: sudut atas membulat, grabber, lalu isi dari pemakai. Tinggi mengikuti isi sampai
/// `maxHeight`; isi yang lebih panjang membuat sheet berhenti di sana dan isinya di-scroll. Geser ke bawah menutup
/// sheet; selama isi di-scroll, hanya dari grabber. Footer dari isi (`bottomSheetFooter`) menempel di tepi bawah dan
/// tidak ikut ter-scroll. `isDismissable` false = geseran dan grabber tidak menutup; grabber tetap tampil supaya
/// tinggi sheet tidak berubah saat kuncinya berganti. Posisi, latar gelap, keyboard, dan animasi masuk milik
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
    private let isDismissable: Bool
    private let isRevealingFocus: Bool
    private let onClose: () -> Void
    private let content: Content

    /// `closeLabel` = label aksesibilitas grabber, yang bagi VoiceOver menjadi tombol tutup. `maxHeight` = tinggi
    /// seluruh sheet termasuk grabber dan `bottomInset`. `isRevealingFocus` false = `BottomSheetFocus` tidak digulir
    /// ke layar; presenter mematikannya selama keyboard tampil, supaya field yang sedang diisi tidak tergeser.
    init(
        closeLabel: String,
        bottomInset: CGFloat,
        maxHeight: CGFloat = .infinity,
        isDismissable: Bool = true,
        isRevealingFocus: Bool = true,
        onClose: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.closeLabel = closeLabel
        self.bottomInset = bottomInset
        self.maxHeight = maxHeight
        self.isDismissable = isDismissable
        self.isRevealingFocus = isRevealingFocus
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
        .accessibilityAction(.escape, close)
        .accessibilityIdentifier(ComponentIdentifier.BottomSheet.root)
    }

    /// Grabber. Bagi VoiceOver ia tombol tutup; pada sheet yang dikunci ia hanya gambar, tanpa tombol dan geseran.
    @ViewBuilder
    private var handle: some View {
        if isDismissable {
            grabber
                .contentShape(Rectangle())
                .gesture(dismissDrag)
                .accessibilityElement()
                .accessibilityLabel(closeLabel)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction(.default, close)
                .accessibilityIdentifier(ComponentIdentifier.BottomSheet.handle)
        } else {
            grabber.accessibilityHidden(true)
        }
    }

    private var grabber: some View {
        Capsule()
            .fill(colors.colorsOutlineNetral)
            .frame(
                width: CustomSizes.BottomSheet.handleWidth.scaledToArtwork,
                height: CustomSizes.BottomSheet.handleHeight.scaledToArtwork
            )
            .padding(.top, FigmaSize.spacingMedium.scaledToArtwork)
            .padding(.bottom, FigmaSize.spacingLarge.scaledToArtwork)
            .frame(maxWidth: .infinity)
    }

    /// Isi yang lebih panjang dari sheet di-scroll, tanpa indikator dan tanpa memantul di ujung; isi yang lebih pendek
    /// tetap di atas. Selalu di dalam `ScrollView` yang sama, hanya scroll-nya yang dinyalakan atau dimatikan:
    /// berpindah wadah membuat SwiftUI membangun ulang isi, sehingga state di dalamnya (mis. centang sementara) hilang
    /// saat isi bertambah panjang. Selama tidak di-scroll, tinggi `ScrollView` mengikuti isi. Begitu mulai di-scroll
    /// (saat pertama terukur, atau setelah isi bertambah, mis. daftar selesai dimuat), `BottomSheetFocus` di isi
    /// digulir ke tengah.
    private var contentArea: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                measuredContent
                    .frame(maxWidth: .infinity)
                    .background(ScrollBounceDisabler(isScrollEnabled: isScrolling))
            }
            .fixedSize(horizontal: false, vertical: !isScrolling)
            .onChange(of: isScrolling) { isScrolling in
                guard isScrolling, isRevealingFocus else { return }
                proxy.scrollTo(BottomSheetFocus.id, anchor: .center)
            }
        }
        .overlayPreferenceValue(BottomSheetFooterKey.self) { pinnedFooter($0) }
    }

    /// Footer yang dititipkan isi lewat `bottomSheetFooter`: menempel di tepi bawah area isi dengan latar permukaan
    /// sheet, jadi baris yang di-scroll lewat di bawahnya. Tempatnya sudah dipesan salinan tak terlihat di ujung isi.
    @ViewBuilder
    private func pinnedFooter(_ footer: AnyView?) -> some View {
        if let footer {
            footer
                .frame(maxWidth: .infinity)
                .background(colors.colorsSurfacePrimary)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    /// Selalu setinggi alaminya, supaya tingginya terbaca utuh walau melewati sheet. Isi beberapa view disusun rapat;
    /// tanpa `VStack` ini `ScrollView` memberi jarak bawaan di antaranya.
    private var measuredContent: some View {
        VStack(spacing: .zero) { content }
            .environment(\.bottomSheetFooterPlacement, .pinned)
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
    /// sendiri jarak geser hampir nol. Sheet yang dikunci tidak ikut bergeser.
    var dismissDrag: some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($dragDistance) { value, distance, _ in
                guard isDismissable else { return }
                distance = max(.zero, value.translation.height)
            }
            .onEnded { value in
                let distance = CustomSizes.BottomSheet.dismissDistance.scaledToArtwork
                guard value.predictedEndTranslation.height > distance else { return }
                close()
            }
    }
}

// MARK: - Actions

private extension BottomSheet {
    func close() {
        guard isDismissable else { return }
        onClose()
    }
}
