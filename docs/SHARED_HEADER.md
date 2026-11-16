# Tahap 2 — shared header dan scroll

Mulai setelah composer tahap 1 stabil. Implementasikan potongan berikut satu per
satu; tidak perlu menyalin seluruh flow chat lama.

```text
DesignKit/Sources/DesignKit/
├── Components/Screen/ScreenHeader.swift
├── Components/Screen/ScreenScaffold.swift
├── Extensions/CGFloat+ScrollProgress.swift
├── Tokens/CustomSizes.swift              # Header: tinggi dan jumlah baris
└── Resources/Assets.xcassets/            # ikon dummy; nama di DesignIcon/DesignColorIcon

TanyaAI/Sources/TanyaAI/
├── Bridging/TanyaAIHost.swift                    # konfigurasi + pembuat halaman untuk host
├── Features/Chat/ChatScreen.swift                # content/menu/composer; layout dari container
├── Features/Chat/Keys/ChatElementIdentifier.swift       # technical identifier, bukan pemetaan copy
└── Resources/{en,id,zh-Hans}.lproj/

TanyaAISandboxApp/HeaderDemoContent.swift # fixture scroll, bukan UI produksi
```

1. Ukuran header sama dengan navigation bar host (keputusan 28 Oktober 2026) agar
   konsisten saat berpindah halaman. Header mulai dari tepi atas layar: padding atas
   `CustomScreenInsets.headerTopWithNotch` 50 atau `headerTop` 28 (tanpa scale, notch bila
   safe area atas > 20), kiri-kanan `CustomSizes.Header.horizontalPadding` 20, bawah
   `bottomPadding` 15, ikon `weightIconSmall` 24. Judul Fira Sans Bold
   `typographySizeDisplayNormal16`, padding `spacingExtraLarge` 32, batas
   `CustomTextLines.headerTitle`. Tinggi total `ScreenHeader.height(isNotched:)`.
2. Buat `ScreenHeader`: slot kiri/kanan sama besar supaya judul tetap di tengah,
   termasuk ketika trailing kosong. Ukuran back dan trailing mengikuti token icon
   dengan `.scaledToArtwork`, tanpa batas minimum SDK. Label dan action datang
   dari caller; tidak ada copy TanyaAI di sini.
   Trailing slot untuk satu action; caller memberi label/tap target yang sesuai.
3. Saat diam, surface transparan sehingga latar screen (warna atau gambar) tembus sampai
   status bar. Selama digulir, surface `colorsSurfacePrimary`, bayangan Figma `Shadow/Default`
   (`designShadow`), dan gradient setinggi `spacingLarge` di bawahnya muncul bertahap sebanding
   `scrollProgress` (0 di posisi teratas, 1 setelah digulir setinggi header; keputusan user
   30 Oktober 2026: progresif, bukan berganti mendadak). Bayangan mengikuti alpha surface. Gradient berada di belakang
   surface agar bayangan tetap terlihat. Bayangan dan gradient berada di luar frame header: tinggi
   header tetap dan sentuhan tidak tertangkap.
   Tidak memakai material blur, jadi tidak ada cabang khusus Reduce Transparency.
4. Buat `ScreenScaffold` untuk menyusun header sebagai overlay di atas konten. `content` menerima tinggi
   header sebagai inset awal, jadi konten tidak tertutup saat posisi teratas dan dapat bergerak di belakang
   header dan bayangan/gradient ketika digulir. Scaffold membaca safe area atas sekali (GeometryReader di root),
   lalu header dan konten mengabaikan safe area atas seperti navigation bar host.
5. Pemilik scroll melaporkan `scrollProgress` 0...1 lewat `CGFloat.scrollProgress(offset:distance:)`: offset
   dibagi `distance`, di bawah toleransi = 0, dan berhenti di 1. Kembali ke atas (termasuk bounce) = 0.
6. Pertahankan composer dan integrasi `TanyaAIHost.makeView()` existing. Header tidak mengubah font 14,
   batas empat baris, keyboard, callback kirim, atau navigation stack host.
   `TanyaAIHost` menampilkan `ChatScreen` langsung. Wrapper `HostedChatScreen` lama
   bukan bagian struktur saat ini. Setiap penghapusan salinan lama memerlukan konfirmasi pemilik.

`ScreenScaffold` adalah reusable layout dengan composition, tanpa inheritance, ViewModel, AnyView, atau
navigation stack baru. `ChatScreen` memberi judul, back callback, content, dan composer sebagai footer; scroll
milik `ChatTable`, yang melaporkan `scrollProgress` dan memakai tinggi header sebagai inset awal. Host tetap
memiliki navigasi. `ScreenHeader` tetap tersedia terpisah.

Contoh:

```swift
ScreenScaffold(
    title: title, backLabel: backLabel, scrollProgress: scrollProgress, onBack: onBack,
    content: { FormContent(headerHeight: $0) }, trailing: { MenuAction() },
    footer: { SubmitAction() }, background: { EmptyView() }
)
```

Judul/label berasal dari localization fitur. Footer mengatur margin luarnya sendiri, dan konten mengatur margin
horizontal serta inset headernya sendiri. Jangan membungkus screen dengan NavigationView baru untuk memakai scaffold.

## Slot kanan dan demo

Chat belum memakai aksi kanan (menu "Percakapan baru" dihapus sampai ada kebutuhan); slot
kanan tetap kosong selebar tombol back sehingga judul tetap di tengah.

Jalankan `Scripts/run_sandbox.sh --language id --header-demo`, lalu buka feature.
Mode ini memberi paragraf dummy yang cukup panjang untuk mencapai akhir, kembali
ke atas, dan melihat teks di belakang header. Tanpa flag, area chat tetap kosong.
Asset back/send masih PDF vector sementara, dengan TODO di xcassets. Ikon `moreMenu` dihapus bersama menu titik
tiga; tambahkan lagi imageset dan case `DesignIcon`-nya saat aksi kanan dibutuhkan.
Localization dan nama asset dibaca melalui `ChatCopy`/`DesignIcon`; lihat
[pola view dan resource](VIEW_TEMPLATE.md).

## Checkpoint sebelum lanjut

- Judul di tengah; ukuran action kiri/kanan mengikuti token desain.
- Posisi awal berjarak dari header. Scroll menampilkan separator dan blur,
  kembali ke atas menghilangkan keduanya, tanpa menggeser header/composer.
- Keyboard dan input empat baris tidak mengubah posisi header. Back menutup
  feature meskipun keyboard terbuka atau konten sedang scroll.
- Label/menu tersedia dalam tiga bahasa. Judul panjang tidak melebar keluar layar.
- Tutup/buka feature tidak menambah navigation stack host; konten/draft lama dilepas.

## Tahap berikutnya, tetap bertahap

Daftar berikut adalah rencana awal tahap header. Arah intent terbaru mengikuti
[pola ReferenceLetter](PACKAGE_STRUCTURE.md#pola-intent-berikutnya).

1. Susun model intent dan step untuk satu contoh BI-FAST, lalu review kontraknya.
2. Buat dummy bubble nominal, rekening tujuan, summary dan receipt. Step yang
   selesai tetap tampil sebagai history dan tidak bisa dipilih ulang.
3. Hubungkan ke logic transfer existing host; dokumen/PIN memakai halaman host.
   Backend/host tetap menentukan hasil transaksi.
4. Setelah model stabil, tambahkan repository history lokal per user/session.
   Pilih storage mengikuti standar host; Core Data SQLite dapat menjadi opsi
   untuk minimum iOS 15. PIN/secret tidak menjadi payload history.

Jangan memulai seluruh tahap tersebut sekaligus. Welcome/sesi baru dibahas saat
model sesi dimulai; belum menjadi implementasi pada PR header ini.
