# Tahap 1 — halaman kosong dan composer

Tuliskan implementasi per bagian, lalu jalankan checkpoint sebelum lanjut.
Target ini sengaja tidak mempunyai session SDK, ViewModel, backend, bubble,
rich text, table, transaction, ThemeManager, atau CopyCatalog. Halaman sambutan
ditambahkan kemudian; lihat [integrasi host](HOST_INTEGRATION.md#halaman-sambutan-dan-menunggu-jawaban).

## Tree

```text
Packages/
├── DesignKit/
│   ├── Package.swift
│   └── Sources/DesignKit/
│       ├── Tokens/
│       │   ├── Generated/                # export engine existing
│       │   ├── CustomSizes.swift         # dimensi point, selalu .scaledToArtwork
│       │   ├── CustomTextLines.swift     # batas baris per peran
│       │   ├── ArtworkScale.swift        # referensi 375 dan rasio layar
│       │   ├── LayoutTolerance.swift     # toleransi pembulatan layout
│       │   ├── CustomBasePaletteColor.swift
│       │   └── CustomColors.swift        # warna tambahan + opacity
│       ├── Extensions/
│       │   ├── CGFloat+Artwork.swift
│       │   ├── Color+Hex.swift
│       │   ├── Image+DesignIcon.swift     # Image/UIImage dari DesignIcon
│       │   ├── String+Resource.swift      # copy sesuai locale host
│       │   ├── View+DesignColors.swift    # theme environment + area default
│       │   └── View+ScrollProgress.swift  # observer umum untuk tahap header
│       ├── Typography/FontFace.swift + FontLoader.swift
│       ├── Resources/Fonts/ + Assets.xcassets/
│       ├── Foundations/Iconography/DesignIcon.swift  # nama ikon = imageset
│       ├── Foundations/Accessibility/
│       └── Components/
│           ├── GrowingTextInput/         # bridge + BoundedTextView
│           ├── MessageComposer/
│           ├── ScreenHeader/             # komponen header
│           └── ScreenContainer/          # header + scroll + footer otomatis
└── TanyaAI/
    └── Sources/TanyaAI/
        ├── Bridging/TanyaAIHost.swift   # API publik: konfigurasi host + makeView()
        ├── Features/
        │   └── Chat/
        │       ├── ChatScreen.swift     # menyusun halaman, memilih bagian yang tampil
        │       ├── Welcome/             # WelcomeSection + WelcomeContent/Greeting/Shortcut
        │       └── Composer/            # ComposerSection (draft lokal)
        ├── Shared/
        │   ├── Keys/                    # ChatCopy, ChatImage, ChatElementIdentifier
        │   └── Extensions/              # String+ChatCopy, Image+ChatImage
        └── Resources/                   # Assets.xcassets + en/id/zh-Hans.lproj
```

## Urutan implementasi

1. Pasang package/resource dan pertahankan `Tokens/Generated` milik Anda.
   Key copy di `ChatCopy` dan nama ikon di `DesignIcon`; tes memastikan
   keduanya sama dengan isi resource. Ikuti [pola view dan resource](VIEW_TEMPLATE.md).
2. Tulis token custom per jenis (`CustomSizes`, `CustomTextLines`), custom palette dan extension sizing/hex. Nilai awal memakai
   nilai bawaan tipe (`.zero`, `String()`), tanpa enum alias. Gunakan `true`/`false` langsung. Padding mengambil `spacingSmall/Medium/Large` langsung. `Color(hex:)` menerima
   RGB, RRGGBB atau AARRGGBB dan memakai fallback nonoptional untuk input invalid.
3. Daftarkan font dengan `FontFace.registerFonts()` saat bootstrap. `FontFace`
   memisahkan nama file dan nama PostScript; `FontLoader` memproses Bundle.module.
   Package berisi Fira Sans Regular/Medium/SemiBold/Bold dan Open Sans
   Regular/Medium/Bold beserta lisensinya. Gunakan nama eksplisit seperti
   `.openSansRegular` atau `.firaSansMedium`; `.regular/.medium` lama diganti.
   Composer default memakai `.openSansRegular`. Chinese menggunakan fallback
   glyph iOS; font Chinese brand final masih dapat diganti kemudian. Pemetaan
   file/PostScript dan sumbernya ada pada [katalog font](../Packages/DesignKit/Sources/DesignKit/Resources/Fonts/SOURCES.md).
4. Buat `BoundedTextView`, lalu bridge `GrowingTextInput`. Intrinsic width tidak
   memaksa lebar konten; tinggi dibatasi empat baris, kemudian scrolling aktif.
   UIKit menentukan geometri caret/seleksi pada semua state. Jangan menggeser
   caret hanya saat kosong: posisinya harus tetap sama dengan saat mengetik.
5. Buat composer: placeholder, field, action, surface. Token ukuran dasar memakai
   `typographySizeDisplaySmall14` dengan leading 21 dari role yang sama.
   Font/leading hanya memakai `.scaledToArtwork`, tanpa `@ScaledMetric` atau
   UIFontMetrics. Pengaturan ukuran teks pengguna tidak mengubah ukuran composer.
   UIKit dan placeholder memakai UIFont fixed yang sama.
   ZStack field memakai `.leading` agar placeholder berada di tengah field,
   sementara geometri caret tetap mengikuti baseline native UIKit.
   Parent hanya memberi Binding, label, palette/font pilihan dan callback kirim.
   Field dan tombol mempunyai minimum tinggi row yang sama, sehingga satu baris
   sejajar tengah. HStack tetap memakai `.bottom`: ketika field membesar, tombol
   bertahan di bawah dan field tumbuh ke atas. Minimum row mengikuti font,
   leading dan ukuran visual tombol.
   Padding semua sisi dan jarak field/tombol memakai `spacingLarge` langsung.
   Pada artwork 375, tombol visual 24 dan padding 16 mengikuti desain, tanpa
   frame interaksi tambahan atau perhitungan kompensasi padding. Frame tombol
   dan tebal stroke memakai `.scaledToArtwork`; tidak ada batas minimum dari SDK.
6. Buat screen: area kosong, `ComposerSection` (draft `@State`) di bawah, margin luar.
   Baca locale host, resolve `R.string.localizable` melalui `String(resource:locale:)`
   dan kirimkan label ke komponen.
7. Host menampilkan `TanyaAIHost.makeView()` lewat navigasinya sendiri, di host SwiftUI
   sebagai tujuan `NavigationLink` pada coordinator yang punya pintu masuk Tanya AI.
   Tombol back atau swipe dari tepi kiri kembali ke halaman asal.
   Lihat [integrasi host](HOST_INTEGRATION.md).

Screen menerima `TanyaAIBridge(transport:)`. Kirim menunggu ack gateway: diterima membersihkan
draft (bila belum diubah), ditolak mempertahankan teks. Draft whitespace menonaktifkan action.
Pertanyaan dan jawaban tampil dari SSE; lihat [chat-gateway](CHAT_GATEWAY.md).

Untuk membuka feature di atas `NavigationView` host existing, lihat
[contoh integrasi host](HOST_INTEGRATION.md), termasuk bootstrap font dan bahasa.

## Menjalankan dan bahasa

`Scripts/run_sandbox.sh --language id`, `en`, atau `zh-Hans`. Tanpa override,
locale mengikuti perangkat. Host mengisi `locale` pada `TanyaAIHost`
dari setting bahasanya; nilai dibaca saat halaman dibuat. `Bundle.module` milik TanyaAI
menyimpan copy, DesignKit tidak menyimpan copy fitur.

UI starter mengikuti light palette Figma. Theme palette tersedia lewat
`.designColors(_:)`; adaptive dark appearance menjadi tahap terpisah. Tiga PDF vector di xcassets masih dummy dengan TODO
penggantian export Figma. Gunakan accessor generated `R.image`, tanpa catalog manual.
Skala mengikuti lebar layar utama, sehingga sheet/split view memerlukan kebijakan
container sebelum diadopsi. Ukuran/shadow tetap dapat disesuaikan melalui token.

## Checkpoint

- Input satu sampai empat baris lalu scroll, termasuk kata panjang dan Chinese.
- Action tetap terlihat di atas keyboard, dengan ukuran mengikuti desain UI/UX.
- Pada artwork 375, padding visual 16, termasuk tombol kanan/bawah dan teks kiri/atas multiline.
- Draft hanya dibersihkan setelah host menerima callback.
- Posisi caret sama sebelum mengetik, setelah huruf pertama dan setelah draft dihapus.
- Label English/Indonesia/Chinese benar dan font tidak menjadi kotak glyph kosong.
- Composer tetap berukuran sama pada pengaturan teks normal maupun accessibility XXXL;
  placeholder memakai font editor. Artwork scaling tetap mengikuti lebar layar.

Tahap setelah composer adalah [shared header dan scroll](SHARED_HEADER.md).
Checkpoint berikutnya berjalan satu per satu: model intent/step, satu flow dummy,
bridge host, kemudian history lokal setelah model stabil. Welcome/sesi bukan
bagian tahap header. Migrasi komponen existing ke `Legacy` tetap terpisah.
