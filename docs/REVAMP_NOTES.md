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

`ScreenContainer` cocok untuk halaman form/konten biasa. Untuk chat dengan ratusan
pesan, gunakan `ScreenHeader` mandiri ditambah list yang memiliki scroll sendiri.
Pada iOS 15:

- `ScrollView` + `LazyVStack` membuat row secara lazy tetapi tidak me-recycle,
  sehingga memori bertambah selama scroll. Row dengan tinggi bervariasi bisa
  meloncat saat scroll ke atas, dan API anchor bawah seperti
  `defaultScrollAnchor`/`scrollPosition` baru ada di iOS 17.
- `List` me-recycle row, tetapi background dan inset sulit dikendalikan di iOS 15
  (`scrollContentBackground` baru iOS 16).
- `scrollTo` pada `LazyVStack` berbaris tidak seragam membuat update SwiftUI berputar
  tanpa henti (main thread 100%, ditemukan di simulator setelah kirim pertanyaan).
  Karena itu `MessagesSection` memakai `VStack`, jadi semua baris di-layout sekaligus.
  Aman untuk satu halaman history (30 pesan); 300 pesan butuh sekitar 12 detik di
  simulator Debug, jadi paging history harus menunggu list ber-recycle.
- **Rekomendasi:** `UITableView` atau `UICollectionView` di dalam
  `UIViewControllerRepresentable`, dengan row SwiftUI. Pakai `UIHostingConfiguration`
  di iOS 16+ dan hosting controller per cell sebagai fallback iOS 15. Branch `main`
  sudah membuktikan pola ini; bawa idenya saja, tanpa lapisan tambahan.

Aturan supaya tetap ringan:

1. Pesan berupa value type dengan ID stabil. ViewModel memegang array; list
   menerapkan `UITableViewDiffableDataSource` snapshot, bukan `reloadData`.
2. Update satu pesan (misalnya jawaban yang sedang streaming) memakai
   `reconfigureItems` (iOS 15), bukan publish ulang seluruh array per token.
3. Rich text/tabel diproses sekali di mapper menjadi model siap tampil; `body` row
   tidak mem-parse atau memformat.
4. History dimuat per halaman (mis. 30–50 pesan) saat mendekati atas.
5. Ukur dengan Instruments di device nyata memakai fixture 500 pesan sebelum
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
