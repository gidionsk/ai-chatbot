# Tahap 1 — halaman kosong dan composer

Tuliskan implementasi per bagian, lalu jalankan checkpoint sebelum lanjut.
Untuk tahap belajar ini, fokus pada font, header, dan composer dahulu.
Kode package sekarang juga memiliki welcome dan percakapan; lihat [integrasi host](HOST_INTEGRATION.md#halaman-sambutan-dan-menunggu-jawaban).

## Tree untuk tahap awal

Tree lengkap kode saat ini ada di [inventori semua file](PACKAGE_TREE.md).
Untuk belajar composer dahulu, fokus pada subset berikut; folder yang lain
sudah menangani welcome, sesi gateway, Markdown, dan daftar percakapan.

```text
DesignKit/Sources/DesignKit/
├── Tokens/Generated/ + token custom
├── Extensions/CGFloat+Artwork.swift + Color+Hex.swift
├── Foundations/
│   ├── Typography/                  # Models/FontFace + FontLoader + Extensions/
│   ├── Iconography/                 # key ikon + accessor Image/UIImage
│   ├── Appearance/                  # palette, card, shadow
│   └── Accessibility/               # ComponentIdentifier
├── Components/
│   ├── Inputs/GrowingTextInput/      # Views/: bridge + BoundedTextView
│   ├── Inputs/MessageComposer/       # Models/ + Views/ + Extensions/
│   └── Screen/                      # ScreenHeader + ScreenScaffold
└── Resources/Fonts/ + Assets.xcassets/

TanyaAI/Sources/TanyaAI/
├── Bridging/TanyaAIHost.swift        # konfigurasi + makeView()
├── Features/Chat/
│   ├── ChatScreen.swift
│   ├── Composer/                    # draft lokal
│   ├── Welcome/                     # Models/ + Views/; bagian Chat
│   ├── Session/TanyaAIBridge.swift   # sesi memakai transport host
│   └── Keys/                        # ChatCopy, ChatImage, identifier, accessor
└── Resources/                       # Assets.xcassets + en/id/zh-Hans.lproj
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
   `.firaSansRegular` atau `.firaSansMedium`; `.regular/.medium` lama diganti.
   Open Sans belum dipakai; semua teks memakai Fira Sans.
   Composer default memakai `.firaSansRegular`. Chinese menggunakan fallback
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
   Baca locale host, resolve `ChatCopy` melalui `String(ChatCopy.placeholder, locale: locale)`
   dan kirimkan label ke komponen.
7. Host menampilkan `TanyaAIHost.makeView()` lewat navigasinya sendiri, di host SwiftUI
   sebagai tujuan `NavigationLink` pada coordinator yang punya pintu masuk Tanya AI.
   Tombol back atau swipe dari tepi kiri kembali ke halaman asal.
   Lihat [integrasi host](HOST_INTEGRATION.md).

Screen menerima `TanyaAIBridge(transport:)`. Pertanyaan yang diterima bridge langsung tampil
secara lokal dan draft dibersihkan; submission yang ditolak mempertahankan draft. Gagal kirim
menjadi bubble gagal. Draft whitespace menonaktifkan action. Stream mengganti salinan lokal; lihat [chat-gateway](CHAT_GATEWAY.md).

Untuk membuka feature di atas `NavigationView` host existing, lihat
[contoh integrasi host](HOST_INTEGRATION.md), termasuk bootstrap font dan bahasa.

## Menjalankan dan bahasa

`Scripts/run_sandbox.sh --language id`, `en`, atau `zh-Hans`. Tanpa override,
locale mengikuti perangkat. Host mengisi `locale` pada `TanyaAIHost`
dari setting bahasanya; nilai dibaca saat halaman dibuat. `Bundle.module` milik TanyaAI
menyimpan copy, DesignKit tidak menyimpan copy fitur.

UI starter mengikuti light palette Figma. Theme palette tersedia lewat
`.designColors(_:)`; adaptive dark appearance menjadi tahap terpisah. Tiga PDF vector di xcassets masih dummy dengan TODO
penggantian export Figma. Gunakan key `DesignIcon`/`DesignColorIcon` dan accessor `Image`/`UIImage`.
Skala mengikuti lebar layar utama, sehingga sheet/split view memerlukan kebijakan
container sebelum diadopsi. Ukuran/shadow tetap dapat disesuaikan melalui token.

## Checkpoint

- Input satu sampai empat baris lalu scroll, termasuk kata panjang dan Chinese.
- Action tetap terlihat di atas keyboard, dengan ukuran mengikuti desain UI/UX.
- Pada artwork 375, padding visual 16, termasuk tombol kanan/bawah dan teks kiri/atas multiline.
- Draft dibersihkan saat bridge menerima pertanyaan lokal; penolakan mempertahankan draft.
- Posisi caret sama sebelum mengetik, setelah huruf pertama dan setelah draft dihapus.
- Label English/Indonesia/Chinese benar dan font tidak menjadi kotak glyph kosong.
- Composer tetap berukuran sama pada pengaturan teks normal maupun accessibility XXXL;
  placeholder memakai font editor. Artwork scaling tetap mengikuti lebar layar.

Tahap setelah composer adalah [shared header dan scroll](SHARED_HEADER.md).
Untuk arah intent berikutnya, ikuti [pola intent](PACKAGE_STRUCTURE.md#pola-intent-berikutnya):
satu flow dahulu, state/service/PIN milik host. Pilihan penyimpanan intent ditentukan
saat kontrak flow stabil; history pesan chat sekarang berasal dari gateway.
