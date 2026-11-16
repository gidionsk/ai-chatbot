//
//  BottomSheetPresenter.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import UIKit

/// Menampilkan `BottomSheet` di atas seluruh view yang dimodifikasi, termasuk header dan area aman: latar gelap
/// memudar masuk, sheet naik dari bawah. Mengetuk latar gelap atau menggeser sheet ke bawah menutupnya, kecuali
/// `isDismissable` false: saat itu hanya `isPresented = false` dari pemakai yang menutup. Keyboard yang dibuka field
/// di dalam isi mendorong sheet ke atasnya. Ini overlay di dalam halaman, bukan presentasi modal UIKit, jadi navigasi
/// host tidak tersentuh dan tetap jalan di iOS 15 dengan tinggi mengikuti isi.
/// TODO: Konfirmasi warna dan opacity latar gelap dengan Figma; sementara estimasi dari foto.
struct BottomSheetPresenter<SheetContent: View>: ViewModifier {
    @Environment(\.designColors) private var colors
    @Environment(\.accessibilityReduceMotion) private var isReducingMotion
    @Binding private var isPresented: Bool
    /// Tepi atas keyboard di koordinat layar selama sheet tampil; nil = keyboard tertutup.
    @State private var keyboardTop: CGFloat?
    private let closeLabel: String
    private let maxHeight: BottomSheetMaxHeight
    private let isDismissable: Bool
    private let contentID: AnyHashable?
    private let sheetContent: () -> SheetContent

    /// `contentID` = identitas isi untuk presentasi berbasis nilai. Nilai lain membangun sheet baru seutuhnya
    /// (isi, tinggi terukur, dan posisi scroll), jadi fokus scroll isi baru dijalankan seperti saat dibuka langsung.
    init(
        isPresented: Binding<Bool>,
        closeLabel: String,
        maxHeight: BottomSheetMaxHeight,
        isDismissable: Bool = true,
        contentID: AnyHashable? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.closeLabel = closeLabel
        self.maxHeight = maxHeight
        self.isDismissable = isDismissable
        self.contentID = contentID
        self.sheetContent = content
    }

    func body(content: Content) -> some View {
        content
            .overlay { layer }
            .onChange(of: isPresented, perform: prepare)
            .onReceive(keyboardChanges, perform: followKeyboard)
    }

    /// Safe area dibaca sebelum diabaikan: sheet menempel di tepi bawah layar dan isinya diberi jarak safe area.
    /// Safe area keyboard dari SwiftUI tidak dipakai, supaya sheet tidak ikut naik selama keyboard halaman (mis.
    /// composer) menutup; keyboard dari isi sheet diikuti lewat `keyboardTop`.
    private var layer: some View {
        GeometryReader { geometry in
            scrim
                .overlay(alignment: .bottom) { sheet(in: layout(in: geometry)) }
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
        .allowsHitTesting(isPresented)
        .animation(slideAnimation, value: isPresented)
        .animation(slideAnimation, value: keyboardTop)
    }

    /// Selalu ada di pohon view supaya memudar masuk dan keluar; saat tersembunyi tidak menangkap sentuhan.
    private var scrim: some View {
        colors.colorsSurfaceOverlay24
            .opacity(isPresented ? CustomColors.Scrim.opacity : .zero)
            .onTapGesture(perform: close)
            .accessibilityHidden(true)
    }

    /// Sheet paling tinggi sampai batasnya; batas bawaan tepat di bawah status bar, jadi tidak pernah layar penuh.
    /// Selama keyboard tampil, sheet duduk tepat di atasnya.
    @ViewBuilder
    private func sheet(in layout: BottomSheetLayout) -> some View {
        if isPresented {
            BottomSheet(
                closeLabel: closeLabel,
                bottomInset: layout.bottomInset,
                maxHeight: layout.sheetMaxHeight,
                isDismissable: isDismissable,
                isRevealingFocus: layout.keyboardHeight == .zero,
                onClose: close,
                content: sheetContent
            )
            .id(contentID)
            .frame(maxHeight: layout.sheetMaxHeight, alignment: .bottom)
            .padding(.bottom, layout.keyboardHeight)
            .transition(.move(edge: .bottom))
        }
    }
}

// MARK: - Helpers

private extension BottomSheetPresenter {
    var slideAnimation: Animation? {
        isReducingMotion ? nil : .easeOut(duration: CustomMotion.sheetSlide)
    }

    /// Keyboard berganti frame: tampil, berubah tinggi, atau menutup.
    var keyboardChanges: NotificationCenter.Publisher {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
    }

    /// Geometri ini belum mengabaikan safe area: tinggi layar = area aman ditambah safe area atas dan bawah.
    func layout(in geometry: GeometryProxy) -> BottomSheetLayout {
        let insets = geometry.safeAreaInsets
        return BottomSheetLayout(
            screenHeight: geometry.size.height + insets.top + insets.bottom,
            safeAreaTop: insets.top,
            safeAreaBottom: insets.bottom,
            keyboardTop: keyboardTop,
            maxHeight: maxHeight
        )
    }
}

// MARK: - Actions

private extension BottomSheetPresenter {
    /// Dari latar gelap, geseran, dan VoiceOver. Sheet yang dikunci hanya ditutup pemakai lewat `isPresented`.
    func close() {
        guard isDismissable else { return }
        isPresented = false
    }

    /// Hanya keyboard yang muncul selama sheet tampil yang diikuti. Di luar itu nilainya dikosongkan, supaya keyboard
    /// halaman (mis. composer) tidak mengangkat sheet berikutnya.
    func followKeyboard(_ change: Notification) {
        guard isPresented else {
            keyboardTop = nil
            return
        }
        keyboardTop = change.keyboardTop
    }

    /// Sheet menempel di tepi bawah layar, jadi keyboard yang masih terbuka akan menutupinya.
    func prepare(isPresenting: Bool) {
        guard isPresenting else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
