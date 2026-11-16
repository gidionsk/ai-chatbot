# Bottom sheet DesignKit

Satu wadah untuk semua sheet: `.bottomSheet(...)` di `Components/Screen/BottomSheet`. Jangan memakai `.sheet` atau
membuat wadah lain per fitur. Wadah hanya memberi latar gelap, permukaan, grabber, tinggi, scroll, dan cara menutup;
judul, padding, dan isi milik pemakai.

## Cara pakai

Satu jenis sheet:

```swift
page
    .bottomSheet(isPresented: $isSheetPresented, closeLabel: closeLabel) {
        OptionList(title: title, items: items, selectedIDs: selectedIDs, onSelect: choose)
    }
```

Beberapa jenis sheet di satu halaman: satu pemasangan dengan enum jenis sheet. Sheet tampil selama nilainya ada, dan
menutup sheet mengosongkannya. Nilai lain membangun sheet baru, jadi centang sementara dan posisi scroll tidak
terbawa, dan fokus isi baru digulir ke layar.

```swift
page
    .bottomSheet(item: $model.sheet, closeLabel: closeLabel) { sheet in
        FormDemoSheetContent(model: model, sheet: sheet)   // switch sheet { case .format: ... case .accounts: ... }
    }
```

Sheet yang untuk sementara tidak boleh ditutup nasabah, mis. selama PIN diperiksa service host:

```swift
page
    .bottomSheet(item: $model.sheet, closeLabel: closeLabel, isDismissable: !model.isVerifying) { sheet in ... }
```

Selama `isDismissable` false, ketuk di latar gelap, geseran, dan VoiceOver tidak menutup sheet, dan grabber tinggal
gambar. Hanya pemakai yang menutup, lewat `isPresented = false` atau mengosongkan `item`.

Tombol yang harus selalu terlihat (mis. "Pilih" di daftar panjang) dipasang dari dalam isi:

```swift
VStack(spacing: .zero) { rows }
    .bottomSheetFooter {
        FilledButton(title: confirmLabel, onTap: confirm)
            .padding(FigmaSize.spacingLarge.scaledToArtwork)
    }
```

Contoh lengkap: `TanyaAISandboxApp/TanyaAI/TanyaAIScreen.swift`, `SheetDemoSheetContent.swift`, dan `FormDemo/`
(`--form-demo`; `--sheet-demo` dengan `--sheet-long`, `--sheet-max`, `--sheet-multi`, `--sheet-locked`,
`--sheet-input`).

Aturan pemasangan:

- Pasang di root halaman, supaya latar gelap menutupi header dan composer.
- `closeLabel` dari copy pemakai; DesignKit tidak punya copy.
- Tinggi mengikuti isi. `maxHeight` hanya batasnya: bawaan tepat di bawah status bar, atau `.screenFraction(0.6)`.
  Di layar tanpa notch (mis. iPhone SE) batas bawaan 16 pt lebih rendah, supaya tarikan dari grabber tidak diambil
  Notification Center.
- Host menahan swipe-back selama sheet terbuka (latar gelap hanya menahan sentuhan di dalam halaman); lihat
  `UINavigationController.setPopGestureEnabled` di sandbox.

## Aturan untuk isi sheet

- Isi tidak punya scroll vertikal sendiri. Isi yang lebih panjang dari batas digulir wadah.
- Bagian yang harus terlihat saat dibuka diberi `.id(BottomSheetFocus.id)`; wadah menggulirnya ke tengah.
  `OptionList` sudah melakukannya untuk pilihan pertama dari `selectedIDs`.
- State sementara boleh `@State` di dalam isi: wadah tidak membangun ulang isi saat isi bertambah panjang.
- Tombol yang menempel di bawah lewat `.bottomSheetFooter { ... }` pada isi, lengkap dengan padding-nya. Footer hanya
  untuk tombol dan teks: ia digambar dua kali (satu memesan tempat di ujung isi), jadi jangan menaruh field atau view
  ber-state di dalamnya. `.disabled(...)` pada isi ikut menonaktifkan footer; modifier environment lain (mis.
  `.designColors`) dipasang langsung pada footer.
- Field teks boleh ada di isi. Saat keyboard terbuka, sheet duduk tepat di atas keyboard dan batas tingginya ikut
  mengecil; isi yang tidak muat lagi di-scroll. Taruh field di bagian atas isi supaya tetap terlihat: wadah tidak
  menggulir ke field yang sedang diisi.
- Isi tidak memanggil service. Hasil pilihan atau input diteruskan lewat callback; service tetap di host.
- Nonaktif lewat `.disabled(...)`, teks lewat `.designFont(role)`.

## Isi yang sudah didukung

| Isi | Status | Catatan |
| --- | --- | --- |
| Daftar satu pilihan | Siap | `OptionList`, ketuk = selesai |
| Daftar banyak pilihan | Siap | `OptionList(mode: .multiple)`; tombol konfirmasi menempel di bawah sheet |
| Daftar yang datanya menyusul | Siap | `items: nil` = spinner; daftar datang kemudian tanpa kehilangan centang |
| Pilihan sebelumnya langsung terlihat | Siap | `selectedIDs` dari pemakai |
| Isi statis: teks, kartu, tombol | Siap | Tinggi mengikuti isi |
| Keypad buatan sendiri (PIN) | Wadah siap, isi belum ada | Tidak memakai keyboard sistem; angka diteruskan ke host |
| Beberapa jenis sheet bergantian | Siap | `.bottomSheet(item:)` |
| Tombol yang menempel di bawah | Siap | `.bottomSheetFooter { ... }` pada isi |
| Isi dengan field teks | Wadah siap | Sheet naik ke atas keyboard; field pencarian di `OptionList` belum ada |
| Sheet yang dikunci | Siap | `isDismissable: false`; hanya pemakai yang menutup |
| Layar tanpa notch (iPhone SE) | Siap | Batas bawaan 16 pt di bawah status bar |

## Belum ada, menunggu desain

| Kebutuhan | Keadaan sekarang |
| --- | --- |
| Pencarian di daftar pilihan | Wadah sudah mengikuti keyboard; field pencarian dan penyaringan di `OptionList` belum dibuat karena belum ada tampilan pastinya |
| Tampilan pasti tombol pilihan banyak | Sementara tombol menempel di bawah tanpa garis atau bayangan pemisah |
| Isi keypad PIN | Hanya wadahnya yang siap, termasuk kunci tutup selama PIN diperiksa |
| Tanda visual sheet terkunci | Grabber tetap tampil supaya tinggi sheet tidak berubah; belum ada tanda lain |

Kemampuan baru untuk semua sheet ditambahkan di wadah (`BottomSheet`, `BottomSheetPresenter`), bukan di isi.
