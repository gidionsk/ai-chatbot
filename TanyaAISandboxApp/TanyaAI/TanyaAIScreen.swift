//
//  TanyaAIScreen.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 20/10/26.
//

import DesignKit
import SwiftUI

/// Konten halaman Tanya AI di host: view SwiftUI dari package, tanpa pembungkus UIKit. Link dari jawaban bot
/// diteruskan ke host; sandbox menampilkan URL-nya sebagai pengganti webview/deeplink host.
@MainActor
struct TanyaAIScreen: ScreenContent {
    @Environment(\.locale) private var locale
    @ObservedObject var viewModel: TanyaAIScreenViewModel
    @State private var openedLink: String?
    @State private var isSheetPresented = false
    /// Pilihan terakhir di sheet contoh; dibuka lagi = sudah tercentang dan terlihat walau daftarnya panjang.
    @State private var sheetChoiceIDs: [String] = []
    @StateObject private var formDemo = FormDemoModel()
    let onBack: () -> Void

    var body: some View {
        page
            .alert(
                String(SandboxCopy.linkTitle, locale: locale), isPresented: isLinkPresented, presenting: openedLink,
                actions: { _ in Button(String(SandboxCopy.linkClose, locale: locale)) {} },
                message: { Text($0) }
            )
            // Sandbox: wadah bottom sheet dipasang di root halaman, jadi header Tanya AI ikut tertutup latar gelap.
            .bottomSheet(
                isPresented: $isSheetPresented,
                closeLabel: String(SandboxCopy.sheetClose, locale: locale),
                maxHeight: sheetMaxHeight,
                isDismissable: !SandboxOptions.current.isSheetLocked
            ) {
                SheetDemoSheetContent(selectedIDs: sheetChoiceIDs, onSelect: choose)
            }
            // Beberapa jenis sheet, satu pemasangan: sheet tampil selama `formDemo.sheet` terisi.
            .bottomSheet(item: $formDemo.sheet, closeLabel: String(SandboxCopy.sheetClose, locale: locale)) { sheet in
                FormDemoSheetContent(model: formDemo, sheet: sheet)
            }
            // Latar gelap hanya menahan sentuhan di dalam halaman; swipe-back milik navigasi host, jadi host yang
            // menahannya selama sheet terbuka. Dibuka lagi saat halaman hilang supaya tidak tertinggal mati.
            .onChange(of: isSheetPresented) { UINavigationController.setPopGestureEnabled(!$0) }
            .onChange(of: formDemo.sheet != nil) { UINavigationController.setPopGestureEnabled(!$0) }
            .onDisappear { UINavigationController.setPopGestureEnabled() }
    }

    @ViewBuilder
    private var page: some View {
        let host = viewModel.host
        // Sandbox: mode --header-demo mengisi area scroll dengan konten contoh.
        if SandboxOptions.current.isHeaderDemo {
            host.makeView(onBack: onBack, onOpenLink: openLink) { HeaderDemoContent() }
        } else if SandboxOptions.current.isFormDemo {
            host.makeView(onBack: onBack, onOpenLink: openLink) { FormDemoContent(model: formDemo) }
        } else if SandboxOptions.current.isSheetDemo {
            host.makeView(onBack: onBack, onOpenLink: openLink) { SheetDemoContent(onOpen: openSheet) }
        } else {
            host.makeView(onBack: onBack, onOpenLink: openLink)
        }
    }

    /// `--sheet-max`: batas tinggi dari tinggi layar; tanpa flag, batas bawaan tepat di bawah status bar.
    private var sheetMaxHeight: BottomSheetMaxHeight {
        guard SandboxOptions.current.isSheetMaxSet else { return .belowStatusBar }
        return .screenFraction(SandboxOptions.sheetMaxFraction)
    }

    private var isLinkPresented: Binding<Bool> {
        Binding(get: { openedLink != nil }, set: { if !$0 { openedLink = nil } })
    }

    private func openLink(_ link: String) {
        openedLink = link
    }

    private func openSheet() {
        isSheetPresented = true
    }

    private func choose(_ ids: [String]) {
        sheetChoiceIDs = ids
        isSheetPresented = false
    }
}
