# Pola view dan resource

Gunakan `MessageComposer`, `ScreenHeader`, dan `ChatScreen` sebagai contoh yang
berjalan. `body` menjelaskan susunan utama; bagian visual yang cukup panjang
dipisah menjadi properti private bernama benda, seperti `field`, `surface`, atau
`actionButton`. View kecil tidak perlu dipecah lagi hanya demi aturan.

## Urutan satu file view

1. Header file atas nama Wendra, import, lalu deklarasi view.
2. `@Environment` yang dibaca view.
3. `@Binding` untuk data caller dan `@State` untuk state lokal.
4. Input immutable `private let`, termasuk callback.
5. Initializer public dengan nama parameter yang jelas.
6. `body`, kemudian bagian visual private yang menghasilkan `View`.
7. `private extension` pada file yang sama untuk helper setup/perhitungan/validasi.
8. `private extension` untuk handler/aksi bila diperlukan.
9. Extension initializer tambahan hanya bila mengurangi pekerjaan caller.

Deklarasi utama memperlihatkan susunan tampilan; extension memperlihatkan
perhitungan dan aksi pendukung. Gunakan `// MARK: - Helpers` dan
`// MARK: - Actions` agar pembagian terlihat di source dan navigator Xcode.
Contoh pada `MessageComposer`: `field`, `actionButton`, dan `surface` tetap di
struct utama; `inputFont`, `singleLineRowHeight`, `lineSpacing`, dan
`isSendEnabled` berada di private extension. `ChatScreen.close/send` berada di
extension Actions.

Stored properties, `@State`, `@Binding`, `@Environment`, dan input callback tetap
di deklarasi utama. Extension tidak menambah stored property. Pertahankan
stored/computed semantics saat merapikan: jangan mengubah waktu perhitungan nilai
hanya untuk memindahkannya. Lifecycle `UIViewRepresentable` dan override UIKit
tetap pada tipe pemilik; helper seperti `applyStyle` dapat dipindahkan ke extension.
View tanpa helper tidak perlu extension tambahan. Pemindahan ke extension adalah
pengorganisasian source, tanpa penambahan object, state, atau cache saat runtime.

Contoh komponen sederhana; semua label diberikan caller agar DesignKit tetap umum:

```swift
import SwiftUI

@MainActor
public struct ActionRow: View {
    private let title: String
    private let onTap: () -> Void

    public init(title: String, onTap: @escaping () -> Void) {
        self.title = title
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            Text(title)
                .padding(FigmaSize.spacingLarge.scaledToArtwork)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

Komponen memiliki padding dalam/surface sendiri. Screen memberi margin luar.

Permukaan yang berulang memakai modifier DesignKit, bukan disusun ulang di setiap view:

| Kebutuhan | Pakai |
| --- | --- |
| Kartu (isi putih, radius, garis tepi, bayangan) | `.cardStyle()`; hanya bayangan: `.cardStyle(isOutlined: false)` |
| Bayangan saja | `.designShadow()` |

```swift
VStack { ... }
    .padding(FigmaSize.spacingLarge.scaledToArtwork)   // padding isi milik komponen
    .cardStyle()
```

Nilainya ada di satu tempat (`CustomSizes.Card`, `CustomSizes.Shadow`, `CustomColors`).
Bila desain mengubah radius atau bayangan kartu, cukup ubah token itu. Tambahkan
modifier baru hanya bila pola yang sama sudah dipakai di lebih dari satu komponen.
Jangan menambahkan padding yang sama pada dua level. Buat `struct View` terpisah
jika mempunyai tanggung jawab sendiri atau dipakai ulang; properti private cukup
untuk potongan layout lokal. ViewModel baru diperlukan ketika ada state/logic
fitur yang memang perlu dimiliki, bukan karena ada sebuah view.

## Screen berikutnya

Pakai composition `ScreenScaffold` agar header, footer, dan latar konsisten. Isi `content`, `trailing`, `footer`,
dan `background`; scroll milik `content`, yang melaporkan `scrollProgress` dan memakai tinggi header sebagai inset
awal. Tidak perlu extend BaseScreen, protocol layout atau BaseViewModel. Lihat pemakaian lengkap pada
`ChatScreen.swift` dan [shared header](SHARED_HEADER.md).

Draft dimiliki section kecil (`ComposerSection`) dengan `@State`; `MessageComposer`
menerima Binding dan callback. Dengan begitu ketikan hanya me-render composer,
bukan header/daftar pesan di screen yang sama. Presenter
host menampilkan `TanyaAIHost.makeView()` sebagai tujuan `NavigationLink` miliknya;
view model halaman dipegang `@StateObject` di view tujuan, bukan dibuat di `body`.

## Callback dan typealias

Callback sederhana ditulis langsung pada pemiliknya:

```swift
private let onBack: () -> Void
private let onSend: (String) async -> Bool
```

Nama menyatakan aksi. Kontrak hasil wajib jelas: `onSend` composer mengembalikan `true`
ketika bridge menerima pertanyaan lokal sehingga draft boleh dibersihkan; `false`
mempertahankan draft. Ack gateway datang setelah itu; kegagalan menjadi bubble gagal.

Tidak perlu satu file `TypeAliases.swift` untuk `Action`, `VoidCallback`, dan
alias callback lain yang sudah mudah dibaca. Gunakan typealias ketika signature
cukup kompleks atau menjadi kontrak domain yang dipakai beberapa API. Letakkan
dekat domain pemilik, dengan nama sesuai tanggung jawab. Typealias hanya nama lain
untuk tipe; tidak memberi penghematan runtime.

Closure bisa mempertahankan reference object. Jika object menyimpan callback yang
menangkap object itu sendiri, gunakan capture yang sesuai, misalnya `[weak self]`.
Tidak perlu menambahkan weak capture pada setiap closure SwiftUI secara otomatis.

## Kapan dipindahkan menjadi komponen bersama

Lihat [tree dan pola intent](PACKAGE_STRUCTURE.md) untuk struktur lengkap.

| Tanggung jawab | Tempat |
| --- | --- |
| Header/container | `DesignKit/Components/Screen` |
| Composer/editor umum | `DesignKit/Components/Inputs` |
| Scroll boundary, sizing, locale resource | `DesignKit/Extensions` |
| Token custom per jenis | `DesignKit/Tokens` |
| Font file dan registrasi | `DesignKit/Foundations/Typography` |
| Identifier UI test komponen | `DesignKit/Foundations/Accessibility` |
| Draft, menu sesi, aturan menerima submission | Screen/fitur pemilik (`TanyaAI/Features/Chat`) |
| API host: konfigurasi, locale/theme, pembuat halaman | `TanyaAI/Bridging` |
| Sesi chat, retry, turn | `TanyaAI/Features/Chat/Session` |
| Format data gateway | `TanyaAI/Features/Chat/Gateway` |
| Penyusunan daftar dan scroll | `TanyaAI/Features/Chat/ConversationList` |
| Navigasi, animasi push, swipe-back | Host (coordinator + destination, atau navigasi aplikasi revamp) |

Komponen umum yang sudah dibutuhkan beberapa caller dibuat reusable. Potongan
yang baru *mungkin* dipakai ulang boleh tetap private sampai tanggung jawabnya
jelas atau ada caller berikutnya. Saat memisahkan, kirim data dan callback dari
caller; jangan memasukkan nama screen, routing fitur atau state bisnis ke DesignKit.

Bagian rumit saat ini terisolasi: `GrowingTextInput`/`BoundedTextView` mengatur
measurement, seleksi dan delegate editor. Navigasi dan animasi halaman memakai
navigasi bawaan milik host. Screen baru cukup memakai API publiknya. Lifecycle bridge mengikuti urutan
make/update/dismantle, dan delegate diputus saat dismantle. Komentar menjelaskan
alasan perilaku khusus, bukan mengulang arti setiap baris.

## Annotation yang digunakan

| API standar | Alasan |
| --- | --- |
| `@State` | Mempertahankan state lokal selama identitas view sama. |
| `@Binding` | Membaca/mengubah state milik caller. |
| `@Environment` | Membaca locale, dismiss, dan preferensi sistem. |
| `@StateObject` | Memiliki reference object yang harus stabil, seperti presenter host. |
| `@ViewBuilder` | Menyusun slot content/trailing/footer tanpa AnyView. |
| `@MainActor` | Menjaga pemilik UI dijalankan pada main actor. |
| `@main` | Entry point sandbox app. |

Tidak ada macro kustom, `@Observable`, `@Model`, `@Namespace`, atau `@ScaledMetric`
pada starter. Tidak ada build tool plugin; resource diakses lewat enum key.
Tidak perlu annotation baru untuk membuat komponen berikutnya.

## Theme

Palette generated (`DefaultColorConstants`, `PremierColorConstants`,
`PrivateColorConstants`) dipilih lewat environment, bukan parameter per komponen:

```swift
// Komponen DesignKit / view fitur
@Environment(\.designColors) private var colors
// Di body: .foregroundColor(colors.colorsTextPrimaryDark)

// Tanya AI: host mengisi palette pada TanyaAIHost (mis. setelah inquiry proposition);
// dibaca saat halaman dibuat
host.colors = PremierColorConstants()

// Layar SwiftUI lain yang memakai DesignKit: pasang di root layar tersebut
SomeScreen()
    .designColors(PremierColorConstants())

// Area yang harus tetap default walaupun theme lain dipilih
PromoBanner()
    .defaultDesignColors()
```

Tanpa `.designColors`, nilainya `DefaultColorConstants`. `TanyaAIHost.colors` dan
`TanyaAIHost.locale` dipasang ke seluruh screen fitur saat halaman dibuat, mengikuti
snapshot konfigurasi host. Warna di luar palette
generated tetap memakai `CustomColors` dan tidak ikut theme.

## Localization otomatis

Tambahkan key yang sama pada `Localizable.strings` English, Indonesia, dan
Chinese Simplified di target pemilik copy, kemudian build. Fitur memiliki copy
fitur; sandbox memiliki copy demo. DesignKit menerima label dari caller.

```swift
@Environment(\.locale) private var locale

// Di dalam feature TanyaAI:
String(ChatCopy.send, locale: locale)
```

Key copy ditulis sekali di enum milik target resource-nya (`ChatCopy` untuk TanyaAI,
`SandboxCopy` untuk sandbox). `String(key:bundle:locale:)` di DesignKit memilih
`.lproj` sesuai locale host, termasuk `zh_CN` ke `zh-Hans`, dengan English sebagai
fallback, lalu mengambil copy dari bundle tersebut. Pemanggilan diulang ketika
environment locale berubah. Key yang tidak ada mengembalikan key itu sendiri.

Menambah copy:
1. Tambah key di `Resources/{en,id,zh-Hans}.lproj/Localizable.strings`.
2. Tambah case di `ChatCopy` dengan raw value key tersebut.
3. `LocalizationTests` gagal bila key enum dan isi ketiga tabel tidak sama persis
   (typo, key lupa diterjemahkan, atau key yang sudah tidak dipakai).

## Ikon

Masukkan imageset ke `DesignKit/Resources/Assets.xcassets`, lalu tambah case dengan
nama yang sama di `DesignIcon` (`Foundations/Iconography`):

```swift
Image(DesignIcon.backArrow)          // SwiftUI, dari DesignKit atau fitur
UIImage(DesignIcon.backArrow)        // UIKit, nil bila imageset tidak ada
```

`AssetTests` memastikan setiap case termuat dari bundle package dan setiap imageset
punya case. `DesignIcon` khusus ikon template. Ikon berwarna utuh (tombol kirim/stop composer,
render original) memakai `DesignColorIcon` dengan nama imageset aset Byon (`send-on`); ilustrasi atau gambar latar nanti
memakai enum sendiri karena tidak di-tint dan ukurannya berbeda.

Tidak memakai R.swift: build tool plugin wajib di-trust per mesin ("Trust & Enable"),
sehingga CI host non-interaktif gagal di langkah "Validate plug-in".

Tiga ikon PDF sementara memiliki TODO penggantian export resmi Figma di
`Assets.xcassets/README.md`. Font tetap memakai `FontFace` karena metadata nama
file dan nama PostScript berbeda; ketujuh font existing tetap dipertahankan.

## Aturan nilai

- Nilai awal: nilai bawaan tipe, `.zero`, `String()`, `[]`. Boolean ditulis
  langsung `true`/`false`. Tidak ada enum alias nilai kosong.
- Pilih file token berdasarkan jenis nilainya:

| File | Isi | `.scaledToArtwork` |
| --- | --- | --- |
| `Generated/FigmaSize` | Spacing, ukuran icon, tipografi dari Figma. **Cek di sini dulu.** | Ya |
| `CustomSizes` | Dimensi point yang belum ada di Figma: `Header` (padding), `Shadow`, `Composer.sendButton` | **Selalu** |
| `CustomTextLines` | Batas baris per peran: `composerInput = 1...4`, `headerTitle` | Tidak pernah |
| `CustomScreenInsets` | Padding atas header dari tepi layar, sama dengan navigation bar host (50/28) | Tidak pernah |
| `CustomColors` / `CustomBasePaletteColor` | Warna semantik tambahan / hex dasarnya | — |
| `ArtworkScale` | Referensi 375×812 dan rasio layar untuk `.scaledToArtwork` | Tidak pernah |
| `LayoutTolerance` | Toleransi pembulatan layout (bukan token desain) | Tidak pernah |

- Contoh: alamat maksimal 5 baris menjadi `CustomTextLines.address = 5`, lalu
  dibungkus komponen peran seperti `AddressText` supaya layar lain tidak menulis
  `.lineLimit` sendiri. Saat batasnya menjadi 7, cukup ubah satu baris.
- Palette generated: dibaca dari `@Environment(\.designColors)`, lihat bagian Theme.
- Konstanta algoritma yang bukan data awal/ukuran disimpan private dekat pemiliknya.

Semua dimensi, termasuk frame tombol dan tebal stroke, memakai `.scaledToArtwork`
langsung dari token/nilai desain. Tidak ada minimum tap/stroke, pembesaran area
tap oleh SDK, atau kompensasi padding untuk frame interaksi tambahan. Padding
composer tetap memakai `spacingLarge` di semua sisi; ukuran interaksi mengikuti
desain UI/UX.

Body tidak melakukan registrasi font, network, parsing berat, atau penyimpanan.
Perubahan scroll ditangani table; header menerima progress sesuai pola scroll yang ada. Potongan view private membuat
kode terbaca; pemisahan tersebut sendiri bukan jaminan performa. Ukur ketika
ada workload yang nyata, dan jalankan pemeriksaan layout/lifecycle existing
sebelum mengubah ownership atau layout bersama.

Properti `private var field: some View` tetap dievaluasi bersama body pemiliknya;
ini bukan batas update tersendiri. Gunakan `struct View` terpisah bila bagian itu
memiliki state/dependency sendiri yang perlu diisolasi. Jangan menambah cache,
ViewModel, typealias, atau generic helper hanya dengan dugaan akan lebih cepat.
Batas empat baris membatasi tinggi editor; panjang teks tetap memengaruhi biaya
measurement. Pengujian paste panjang tidak berarti panjang input tak terbatas
akan selalu murah.
