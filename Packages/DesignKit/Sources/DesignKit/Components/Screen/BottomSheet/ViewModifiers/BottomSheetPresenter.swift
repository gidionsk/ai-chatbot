//
//  BottomSheetPresenter.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI
import UIKit

/// Menampilkan `BottomSheet` di atas seluruh view yang dimodifikasi, termasuk header dan area aman: latar gelap
/// memudar masuk, sheet naik dari bawah. Mengetuk latar gelap atau menggeser sheet ke bawah menutupnya. Ini overlay
/// di dalam halaman, bukan presentasi modal UIKit, jadi navigasi host tidak tersentuh dan tetap jalan di iOS 15
/// dengan tinggi mengikuti isi.
/// TODO: Konfirmasi warna dan opacity latar gelap dengan Figma; sementara estimasi dari foto.
struct BottomSheetPresenter<SheetContent: View>: ViewModifier {
    @Environment(\.designColors) private var colors
    @Environment(\.accessibilityReduceMotion) private var isReducingMotion
    @Binding private var isPresented: Bool
    private let closeLabel: String
    private let maxHeight: BottomSheetMaxHeight
    private let sheetContent: () -> SheetContent

    init(
        isPresented: Binding<Bool>,
        closeLabel: String,
        maxHeight: BottomSheetMaxHeight,
        @ViewBuilder content: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self.closeLabel = closeLabel
        self.maxHeight = maxHeight
        self.sheetContent = content
    }

    func body(content: Content) -> some View {
        content
            .overlay { layer }
            .onChange(of: isPresented, perform: prepare)
    }

    /// Safe area dibaca sebelum diabaikan: sheet menempel di tepi bawah layar dan isinya diberi jarak safe area.
    /// Keyboard tidak dihitung, supaya sheet tidak ikut naik selama keyboard menutup.
    private var layer: some View {
        GeometryReader { geometry in
            scrim
                .overlay(alignment: .bottom) { sheet(in: geometry) }
                .ignoresSafeArea()
        }
        .ignoresSafeArea(.keyboard)
        .allowsHitTesting(isPresented)
        .animation(slideAnimation, value: isPresented)
    }

    /// Selalu ada di pohon view supaya memudar masuk dan keluar; saat tersembunyi tidak menangkap sentuhan.
    private var scrim: some View {
        colors.colorsSurfaceOverlay24
            .opacity(isPresented ? CustomColors.Scrim.opacity : .zero)
            .onTapGesture(perform: close)
            .accessibilityHidden(true)
    }

    /// Sheet paling tinggi sampai batasnya; batas bawaan tepat di bawah status bar, jadi tidak pernah layar penuh.
    @ViewBuilder
    private func sheet(in geometry: GeometryProxy) -> some View {
        if isPresented {
            BottomSheet(
                closeLabel: closeLabel,
                bottomInset: geometry.safeAreaInsets.bottom,
                maxHeight: sheetMaxHeight(in: geometry),
                onClose: close,
                content: sheetContent
            )
            .frame(maxHeight: sheetMaxHeight(in: geometry), alignment: .bottom)
            .transition(.move(edge: .bottom))
        }
    }
}

// MARK: - Helpers

private extension BottomSheetPresenter {
    var slideAnimation: Animation? {
        isReducingMotion ? nil : .easeOut(duration: CustomMotion.sheetSlide)
    }

    /// Geometri ini belum mengabaikan safe area: dari tepi bawah layar sampai tepat di bawah status bar = area aman
    /// ditambah safe area bawah, dan tinggi layar = area aman ditambah safe area atas dan bawah.
    func sheetMaxHeight(in geometry: GeometryProxy) -> CGFloat {
        let insets = geometry.safeAreaInsets
        let limit = geometry.size.height + insets.bottom
        return maxHeight.resolved(screenHeight: limit + insets.top, limit: limit)
    }
}

// MARK: - Actions

private extension BottomSheetPresenter {
    func close() {
        isPresented = false
    }

    /// Sheet menempel di tepi bawah layar, jadi keyboard yang masih terbuka akan menutupinya.
    func prepare(isPresenting: Bool) {
        guard isPresenting else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
