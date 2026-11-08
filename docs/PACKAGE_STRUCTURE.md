# Struktur package berdasarkan fungsi

Struktur ini berlaku untuk kode yang ada sekarang. Folder memisahkan tanggung jawab,
bukan menambah layer runtime atau target SPM. `import DesignKit`, `import TanyaAI`,
dan API host tetap sama. Token generated, font, aset, dan lokalisasi tetap di tempatnya.

## DesignKit

```text
Sources/DesignKit/
├── Components/
│   ├── Actions/                     # ActionCard, SuggestionChip
│   ├── Images/                      # RemoteImage; satu pintu Kingfisher
│   ├── Inputs/
│   │   ├── GrowingTextInput/         # editor UIKit + bridge SwiftUI
│   │   └── MessageComposer/          # field, action kirim/stop, button style
│   ├── Lists/HostedTable/            # hosting cell + pengukuran layout table
│   ├── Markdown/
│   │   ├── MarkdownContent.swift     # view publik
│   │   ├── MarkdownDocument.swift    # dokumen yang sudah di-parse
│   │   ├── Parsing/                 # parser, pohon sementara, aturan sintaks
│   │   ├── Blocks/                  # hasil parse: paragraf, list, tabel, dst.
│   │   └── Rendering/               # view blok dan styling teks inline
│   ├── Messages/                    # DateChip + MessageBubble/shape
│   └── Screen/                      # ScreenHeader + ScreenScaffold
├── Foundations/
│   ├── Accessibility/               # ComponentIdentifier
│   ├── Appearance/                  # palette environment, card, shadow
│   ├── Iconography/                 # key ikon + Image/UIImage accessor
│   └── Typography/                  # FontFace, FontLoader, SwiftUI accessor
├── Extensions/                      # artwork, hex, resource locale, scroll progress
├── Tokens/
│   ├── Generated/                   # tetap milik export engine
│   └── ...                          # ukuran/warna/batas baris custom
└── Resources/                       # Fonts + Assets.xcassets
```

Komponen satu file langsung berada dalam kelompok fungsinya. Folder komponen dibuat
bila implementasinya terdiri dari beberapa file, seperti `GrowingTextInput`.
Model, helper, dan extension khusus komponen tinggal bersamanya. Contoh:
`AttributedString+MarkdownStyle` berada di `Markdown/Rendering`, karena bukan
extension string untuk seluruh aplikasi.

`Foundations` berisi dukungan lintas komponen: font, ikon, palette, dan surface.
`Extensions` hanya untuk fungsi kecil yang memang lintas komponen. Jangan menaruh
flow transfer, validasi rekening, atau model service host di DesignKit.

## TanyaAI

```text
Sources/TanyaAI/
├── Bridging/
│   ├── TanyaAIHost.swift             # konfigurasi + makeView()
│   ├── TanyaAIChatTransport.swift    # kontrak HTTP/SSE yang diimplementasi host
│   └── TanyaAITransportError.swift
├── Features/Chat/
│   ├── ChatScreen.swift             # menyusun header, daftar, footer
│   ├── Welcome/                     # section + data sambutan dari host
│   ├── Composer/                    # draft lokal dan aksi kirim/stop
│   ├── FollowUps/                   # saran pertanyaan berikutnya
│   ├── Messages/                    # nilai pesan, merge, local question, MessageRow
│   ├── ConversationList/
│   │   ├── ChatTable.swift          # SwiftUI ↔ UIKit
│   │   ├── ChatTableController.swift # snapshot dan lifecycle table
│   │   ├── ChatTableState.swift     # input update table
│   │   ├── Rows/                    # item, ID, input/action, penyusunan view baris
│   │   ├── Dates/                   # pengelompokan hari dan label tanggal
│   │   └── Scrolling/               # parkir pertanyaan, anchor, follow latest
│   ├── Session/
│   │   ├── TanyaAIBridge.swift      # pemilik state sesi; tetap public
│   │   ├── TanyaAIBridge+Connection.swift
│   │   ├── TanyaAIBridge+Turn.swift
│   │   └── ...                      # connection, backoff, turn, history phase
│   ├── Gateway/
│   │   ├── ChatWire.swift           # metadata protokol
│   │   ├── ChatHistoryPage.swift    # decode halaman history di background
│   │   ├── Responses/              # WireInit, WireMessage, ack/error, dst.
│   │   ├── Decoding/               # konfigurasi JSONDecoder dan tanggal wire
│   │   └── Streaming/              # framing SSE → ChatEvent
│   └── Keys/                       # ChatCopy, ChatImage, ID, accessor-nya
└── Resources/                      # Assets.xcassets + en/id/zh-Hans.lproj
```

`Welcome` adalah bagian Chat, bukan feature atau screen tersendiri.
`Messages` mengurus isi pesan; `ConversationList` mengurus bagaimana seluruh
percakapan disusun dan digulir, termasuk welcome, tanggal, serta follow-up.
`Gateway` memahami format data server; `Session` memahami kapan menyambung,
menggabungkan pesan, dan membuka kembali tombol kirim.

`TanyaAIBridge` tetap dibuat sekali oleh host dan diberikan ke `TanyaAIHost`.
Lokasi source-nya mengikuti pemilik fungsi, yaitu sesi Chat. Memindahkan folder
tidak mengubah akses public atau cara host memanggilnya.

Key Chat dipindahkan dari `Shared` ke Chat karena saat ini hanya fitur itu yang
memakainya. Naikkan ke lokasi bersama ketika ada pengguna lain yang nyata.
Tests mengikuti jalur fungsi Sources; helper test tetap di `Tests/.../Support`.

## Alur yang berjalan sekarang

```text
Host membuat transport + TanyaAIBridge + TanyaAIHost
    → ChatScreen menjalankan lifecycle sesi
    → Session memanggil transport host: init → history → SSE
    → Gateway decode; Messages menyiapkan nilai pesan/Markdown
    → ConversationList memperbarui baris berdasarkan ID
    → MessageRow merender dengan komponen DesignKit

Composer/Welcome/FollowUps
    → aksi ke TanyaAIBridge
    → transport host
    → ack/event kembali melalui Session
```

HTTP, autentikasi, PIN, dan navigasi tetap milik host. `TanyaAIBridge` menangani
sesi chat-gateway, bukan orkestrasi seluruh transaksi bisnis.

## Pola intent berikutnya

Berikut rencana untuk intent pertama, belum folder atau implementasi tambahan.
Buat satu flow `ReferenceLetter` sampai selesai sebelum mengekstrak kebutuhan bersama.

```text
TanyaAI/Features/Chat/Intents/ReferenceLetter/
├── ReferenceLetterView.swift         # memilih form/loading/summary sesuai state
├── ReferenceLetterFormView.swift     # input + aksi; tidak hit service
├── ReferenceLetterSummaryView.swift  # hasil read-only
├── ReferenceLetterState.swift        # kondisi UI flow ini
├── ReferenceLetterDraft.swift        # nilai form
└── ReferenceLetterSummary.swift      # data hasil untuk ditampilkan

HostApp/Features/TanyaAI/Intents/
├── ChatIntentHandler.swift           # arahkan jenis intent ke flow host
├── ChatIntentContent.swift           # pasang view sesuai instance intent
└── ReferenceLetter/
    ├── ReferenceLetterContent.swift   # hubungkan view dengan view model host
    └── ReferenceLetterViewModel.swift # draft/state + aksi flow

HostApp/Features/ReferenceLetter/      # pakai logic bisnis existing host
└── ...                              # use case/service + rute PIN/receipt
```

Nama dan jumlah file disesuaikan dengan kebutuhan nyata. View kecil boleh satu file;
model satu pemakai tetap dekat view pemilik. Tidak perlu ViewModel di setiap view,
repository baru bila service existing sudah mencukupi, atau `BaseIntent`.

Untuk contoh surat referensi:

1. Host menerima jenis intent dan membuat **instance ID** untuk kemunculan flow itu.
2. View model host memanggil validasi existing. Hasilnya mengisi state form.
3. Form mengubah draft melalui binding; tombol Kirim menyampaikan aksi ke host.
4. Host submit dan membuka PIN melalui coordinator existing. Data PIN tidak masuk
   model TanyaAI atau payload history.
5. Host menerima hasil final service, lalu mengubah state instance yang sama menjadi
   summary. **ID baris tetap**, sehingga form berubah di tempat.

Jenis intent (`referenceLetter`) berbeda dari instance ID: nasabah dapat membuat
surat referensi lebih dari sekali dalam percakapan yang sama. State dimiliki host
selama flow hidup, bukan sel table, sehingga tidak hilang saat sel di-recycle.
Riwayat selesai berupa snapshot read-only; membuka history tidak memanggil ulang
service. Hasil terlambat harus dicocokkan ke instance/request yang masih aktif;
double submit, pembatalan PIN, dan retry mengikuti aturan use case host.

Slot `makeView { content }` sekarang hanya satu baris sisipan di akhir daftar.
Itu belum API untuk banyak intent. Saat implementasi intent pertama, tambahkan
item intent ber-ID stabil dan penyedia view per item. Detail kontraknya diputuskan
bersama flow pertama, tanpa mengubah slot existing diam-diam pada perapian ini.

## Aturan menambah kode

| Yang ditambahkan | Pemilik |
| --- | --- |
| Field, picker, tombol, kartu generik | DesignKit, kelompok fungsi yang sesuai |
| Layout/form/summary khusus intent | TanyaAI `Chat/Intents/<NamaIntent>` |
| Draft dan urutan aksi transaksi aktif | View model host per instance intent |
| Service, eligibility bisnis, PIN, receipt resmi | Use case/service/coordinator existing host |
| Format respons chat-gateway | TanyaAI `Chat/Gateway` |
| Penyambungan, retry, turn chat | TanyaAI `Chat/Session` |
| Penyusunan baris atau aturan scroll | TanyaAI `Chat/ConversationList` |
| Font, palette, ikon generik | DesignKit `Foundations` |

Ikuti [pola view](VIEW_TEMPLATE.md): input/state, initializer, body, bagian visual,
kemudian extension Helpers dan Actions. Jangan membuat folder `Models`/`Views`
global, catalog callback, generic flow engine, atau kelas dasar agar semua file
terlihat seragam. Kesamaan pola adalah kesamaan tanggung jawab.

## Batas perubahan dan performa

Perapian ini memindahkan source dan tests, membedakan blok Helpers/Actions, serta
memperbarui jalur pemeriksaan. Tidak menambah dependency, object, subscription,
parsing di `body`, atau state baru. Nilai token/resource dan algoritma scroll,
measurement editor, penggabungan pesan, serta parsing Markdown tetap sama.

Ini bukan klaim bebas bug atau peningkatan FPS. Checkpoint-nya adalah build package
dan host, tes package, serta UI/lifecycle existing. Ketika intent dibuat, ketikan
form harus diamati di row pemilik, bukan memicu pembangunan ulang seluruh chat;
service tidak dimulai dari `body`/`onAppear` sel. Ukur lagi dengan flow tersebut.

Package tetap dua target saat ini. Pemisahan ke banyak package/target baru belum
diperlukan hanya untuk mengelompokkan file.
