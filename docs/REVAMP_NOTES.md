# Keputusan revamp dan tahap berikutnya

Ringkasan keputusan yang sudah diambil untuk starter ini, ditambah saran untuk
tahap yang belum dikerjakan. Dokumen lain menjelaskan cara memakai API; dokumen
ini menjelaskan alasannya.

## Keputusan yang berlaku

| Topik | Keputusan | Alasan |
| --- | --- | --- |
| Minimum OS | iOS 15 untuk package, sandbox dan host | Host ikut naik ke iOS 15 pada journey revamp. |
| Resource | Enum key manual (`ChatCopy`, `DesignIcon`), tanpa R.swift | Build tool plugin R.swift gagal di CI host (validasi plugin non-interaktif); tes menjaga enum tetap sama dengan resource. |
| Ukuran | 1:1 Figma lewat `.scaledToArtwork` | Termasuk area tap 24pt; tidak ada minimum 44. Keputusan UI/UX. |
| Theme | `@Environment(\.designColors)`; host mengisi `colors` pada `TanyaAIHost` | Tanpa singleton; `.defaultDesignColors()` untuk area bebas theme. Dibaca saat halaman dibuat. |
| Bahasa | Host mengisi `locale` pada `TanyaAIHost` dari Localize_Swift | Host tidak memakai SwiftUI locale. Dibaca saat halaman dibuat; bahasa diganti dari Settings, bukan saat Tanya AI terbuka, jadi tidak perlu live update. |
| Nilai awal | `.zero`, `String()`, `[]` | Tidak ada literal tersebar dan tidak ada enum alias. |
| Token custom | Dipisah per jenis: `CustomSizes`, `CustomTextLines` (`CustomMotion` saat ada animasi) | Aturan scaling jelas per file dan dijaga script; satu tempat untuk mengubah nilai per peran. |
| Draft | `ComposerSection` memiliki `@State` | Ketikan tidak me-render ulang header/daftar pesan. |
| Navigasi | Package memberi view SwiftUI `makeView()`. Host SwiftUI: coordinator + destination (`@StateObject`), didaftarkan di coordinator yang punya pintu masuk | Memakai rute yang sudah ada, tanpa UIKit ganda; view model hidup selama halaman tampil; blocker host tetap berlaku. Akses "dari mana saja" menunggu navigasi revamp (mis. `NavigationStack` dengan path). |

## Daftar pesan untuk ratusan chat

`ScreenContainer` cocok untuk halaman form/konten biasa. Daftar pesan memakai `ChatTable`
(`UITableView` di dalam `UIViewControllerRepresentable`, baris SwiftUI) di dalam `ScreenScaffold`,
karena scroll-nya milik table. Pilihan lain pada iOS 15:

- `ScrollView` + `LazyVStack` membuat row secara lazy tetapi tidak me-recycle, dan
  `scrollTo` pada baris tidak seragam membuat update SwiftUI berputar tanpa henti
  (main thread 100%, ditemukan di simulator setelah kirim pertanyaan).
- `ScrollView` + `VStack` aman dari itu, tetapi semua baris di-layout sekaligus dan
  biayanya naik mengikuti jumlah pesan.
- `List` me-recycle row, tetapi background dan inset sulit dikendalikan di iOS 15
  (`scrollContentBackground` baru iOS 16).

Sel memakai `UIHostingConfiguration` di iOS 16+ dan hosting controller di iOS 15
(`HostingTableViewCell`). Controller-nya `UIViewController` biasa supaya keyboard dan safe area
hanya diatur SwiftUI.

Hal yang harus dijaga, semuanya pernah menjadi bug nyata saat migrasi:

1. **Snapshot lewat batch update.** `apply(animatingDifferences: false)` berperilaku seperti
   `reloadData`: tinggi terukur hilang, posisi pindah ke baris lain, dan baris bisa tampil ganda.
   Pakai `animatingDifferences: true` di dalam `UIView.performWithoutAnimation`, lalu `layoutIfNeeded`
   sebelum menghitung posisi.
2. **Tinggi terukur disimpan per baris** dan dikembalikan lewat `estimatedHeightForRowAt`.
3. **`contentSize` bukan ujung sebenarnya** selama ada baris belum terukur. Saat membuka history,
   bidik baris terakhir dengan `scrollToRow`, bukan `contentSize`.
4. **Posisi baca berpatokan pada baris, bukan offset.** Penelusuran aksesibilitas (XCUITest, dan
   diduga VoiceOver) mengukur semua baris tanpa scroll, sehingga tinggi konten berubah dan table tidak
   mengoreksi offset. Baris acuan hanya direkam saat posisi pasti; scroll terprogram yang belum
   ter-layout masih melaporkan baris lama.
5. **`contentInsetAdjustmentBehavior = .always`, bukan `.never`.** Table membentang sampai tepi atas layar
   di belakang header. Dengan `.never`, safe area diteruskan ke sel dan menambah tinggi baris (62 pt di
   iPhone 17 Pro). `contentInset.top` dikurangi safe area, jadi `adjustedContentInset` tetap
   tinggi header + jarak.
6. **Sel hosting tidak mewarisi environment SwiftUI.** `designColors` dan `locale` dipasang di
   `ChatScreen.listRow`, dan `.id(item.id)` mencegah `@State` terbawa saat sel dipakai ulang.
7. **`headerHeight` berubah setelah render pertama**, karena safe area baru terbaca setelah halaman terpasang.
8. **Id ganda membuat diffable data source crash**, dan id pesan berasal dari server, jadi dibuang di
   `[ChatListItem](rows:)`.
9. **Bawah didahulukan saat tinggi table berubah.** Nasabah di ujung daftar tetap di ujung saat keyboard
   muncul atau tertutup; acuan posisi baca hanya untuk nasabah yang sedang membaca ke atas. Kalau keduanya
   dijalankan, acuan lama mengembalikan daftar dan bagian bawah tertutup setinggi keyboard.
10. **Sel yang tampil tidak mengikuti update SwiftUI.** Mengganti `makeCell` hanya menjangkau sel berikutnya.
    Nilai yang dibaca baris harus masuk `ChatListItem` atau `ChatRowInputs`; konten sisipan yang tidak bisa
    dibandingkan disegarkan lewat `refreshInjectedContent`. Jangan menyegarkan semua sel di tiap update:
    halaman berubah di tiap token stream. `onOpenLink` masih closure dari saat sel dibuat.

Aturan supaya tetap ringan:

1. Pesan berupa value type dengan ID stabil. Isi yang berubah memakai `reconfigureItems`
   (iOS 15), bukan publish ulang seluruh array per token.
2. Rich text/tabel diproses sekali di mapper menjadi model siap tampil; `body` row
   tidak mem-parse atau memformat.
3. History dimuat per halaman (mis. 30–50 pesan) saat mendekati atas.
4. Ukur dengan Instruments di device nyata memakai fixture 500 pesan sebelum
   menyimpulkan performa. Hasil simulator bukan FPS produksi.

## Skala artwork, `UIScreen.main`, dan iPhone lipat

`UIScreen.main` deprecated sejak iOS 16. Warning baru muncul saat minimum target
dinaikkan ke 16, jadi starter iOS 15 belum terdampak. Masalah utamanya bukan
deprecation, melainkan sumber lebarnya:

- Rumus tanpa cap membuat semua ukuran membesar bila lebar bertambah. Pada layar
  lipat yang terbuka (jauh di atas 375pt), font 14 bisa menjadi lebih dari 20.
- Lebar dapat berubah saat aplikasi berjalan (lipat/buka, multitasking), sementara
  nilai statis hanya terbaca ulang saat `body` kebetulan dievaluasi.

Saran bertahap:

1. **Sekarang (iPhone, portrait):** pertahankan rumus. Tidak perlu perubahan.
2. **Sebelum mendukung perangkat lipat/iPad:** sepakati dengan UI/UX batas lebar
   referensi (cap) atau pindah ke layout adaptif untuk size class regular, misalnya
   skala 1.0 dengan lebar konten maksimum.
3. **Implementasi:** ambil lebar dari container fitur, bukan layar. Hosting controller
   fitur sudah dimiliki `TanyaAIHost`; ia dapat mengukur lebar view-nya dan
   menyuntikkannya lewat environment agar SwiftUI render ulang saat lebar berubah.
   Ini mengubah aturan "tanpa artwork environment" yang berlaku sekarang, jadi
   putuskan bersama tim ketika target perangkat lipat sudah pasti.

## Seam backend (contract belum ada)

Endgame: host yang memanggil service, TanyaAI menerima payload dan menerjemahkannya
ke UI. Buat seam paling tipis saat migrasi pengiriman dimulai:

```swift
// Host yang melakukan network; TanyaAI hanya decode + map ke model UI.
public protocol TanyaAIChatService {
    func send(_ text: String) async throws -> Data
}
```

- Diperbarui 28 Oktober 2026: seam final adalah `TanyaAIChatTransport` per endpoint milik host
  (body mentah, baris SSE apa adanya). TanyaAI men-decode dan mengatur init → history → SSE,
  retry, dan merge di `TanyaAIBridge`. Lihat [chat-gateway](CHAT_GATEWAY.md).
- `ResponseDTO` dan mapper bersifat internal di TanyaAI. Saat contract berubah,
  hanya dua file ini yang ikut berubah.
- Implementasi dummy ada di Sandbox, bukan di package produksi.
- Mulai dari request/response biasa. Ganti ke `AsyncThrowingStream` hanya jika
  backend memang streaming.
- Jangan memindahkan DependencyContainer, Coordinator, atau file alias dari `main`
  sebelum ada kebutuhan nyata.

## Persiapan Swift 6

Package masih memakai `swift-tools-version: 5.7`. Sebelum revamp, naikkan tools
version dan aktifkan strict concurrency secara bertahap. Contoh yang akan muncul:
`FontLoader.registered` berupa `static var` mutable yang dijaga `NSLock`.
