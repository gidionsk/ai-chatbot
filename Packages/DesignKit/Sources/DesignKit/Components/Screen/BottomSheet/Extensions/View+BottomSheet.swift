//
//  View+BottomSheet.swift
//  DesignKit
//
//  Created by Wendra on 12/11/26.
//

import SwiftUI

public extension View {
    /// Bottom sheet di atas seluruh view ini; pasang di root halaman supaya header dan composer ikut tertutup latar
    /// gelap. Tinggi sheet mengikuti `content`, yang membawa judul dan padding-nya sendiri (daftar pilihan, keypad,
    /// dan lainnya). Isi yang lebih panjang dari `maxHeight` membuat sheet berhenti di sana dan isinya di-scroll;
    /// batas bawaan tepat di bawah status bar, `.screenFraction(0.6)` = paling tinggi 60% layar. Menutup lewat ketuk
    /// latar gelap, geser ke bawah, atau `isPresented = false` dari pemakai. `isDismissable` false = sheet dikunci:
    /// latar gelap, geseran, dan VoiceOver tidak menutupnya, hanya `isPresented = false` dari pemakai (mis. selama
    /// PIN diperiksa service host). `closeLabel` = label aksesibilitas untuk menutup, dari copy pemakai. Isi tidak
    /// boleh punya scroll vertikal sendiri (sheet yang menggulirnya). Field di dalam isi boleh membuka keyboard:
    /// sheet naik ke atas keyboard dan batas tingginya ikut mengecil.
    func bottomSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        closeLabel: String,
        maxHeight: BottomSheetMaxHeight = .belowStatusBar,
        isDismissable: Bool = true,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(
            BottomSheetPresenter(
                isPresented: isPresented,
                closeLabel: closeLabel,
                maxHeight: maxHeight,
                isDismissable: isDismissable,
                content: content
            )
        )
    }

    /// Versi berbasis nilai, untuk halaman yang punya beberapa jenis sheet: sheet tampil selama `item` tidak nil dan
    /// isinya dibangun dari nilai itu, biasanya enum jenis sheet. Menutup sheet mengosongkan `item`. Nilai lain =
    /// sheet baru seutuhnya, jadi state di dalam isi (mis. centang sementara `OptionList`) dan posisi scroll tidak
    /// terbawa dari sheet sebelumnya, dan fokus isi baru (`BottomSheetFocus`) digulir ke layar. Satu pemasangan di
    /// root halaman cukup untuk semua sheet halaman itu.
    func bottomSheet<Item: Hashable, SheetContent: View>(
        item: Binding<Item?>,
        closeLabel: String,
        maxHeight: BottomSheetMaxHeight = .belowStatusBar,
        isDismissable: Bool = true,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(
            BottomSheetPresenter(
                isPresented: item.isPresent(),
                closeLabel: closeLabel,
                maxHeight: maxHeight,
                isDismissable: isDismissable,
                contentID: item.wrappedValue.map(AnyHashable.init),
                content: {
                    if let value = item.wrappedValue {
                        content(value)
                    }
                }
            )
        )
    }

    /// Dipasang pada isi sheet: `footer` (mis. tombol konfirmasi beserta padding-nya) menempel di tepi bawah sheet dan
    /// tidak ikut ter-scroll, sementara isi di atasnya digulir sampai di atas footer. Di luar sheet, footer tampil
    /// biasa di bawah isi. Untuk tombol dan teks saja: footer digambar dua kali (satu memesan tempat), jadi jangan
    /// menaruh field atau view ber-state di dalamnya. `.disabled` pada isi ikut menonaktifkan footer. Modifier
    /// environment lain yang dipasang pada isi (mis. `.designColors`) tidak sampai ke footer yang ditempel; pasang
    /// langsung pada footer.
    func bottomSheetFooter<Footer: View>(@ViewBuilder footer: () -> Footer) -> some View {
        modifier(BottomSheetFooterModifier(footer: footer()))
    }
}
