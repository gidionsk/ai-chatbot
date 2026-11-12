# Penempatan file DesignKit dan TanyaAI

Pola repository adalah **fungsi/pemilik → jenis file → implementasi**.

## Aturan penempatan

| Jenis | Tempat dan batas tanggung jawab |
| --- | --- |
| Tampilan | `Views/`: SwiftUI View, UIView, cell, Shape, ButtonStyle, dan adapter representable. Menerima data/binding/callback. |
| Data | `Models/`: nilai pesan, konfigurasi, payload, enum, dan state. Model boleh memiliki initializer/mapping data. |
| Controller UIKit | `Controllers/`: lifecycle UIViewController, table, atau hosting controller. |
| Protocol internal komponen | `Protocols/`: kontrak perilaku milik komponen, seperti `HostedContentAttaching`. |
| Extension bantu | `Extensions/`: accessor atau transform pada tipe yang sudah ada, misalnya `Array+ChatMessage`. |
| Modifier tampilan bersama | `ViewModifiers/` dalam pemiliknya, seperti `Foundations/Appearance`. |
| Key resource | `Keys/`: nama copy, ikon, identifier, dan tautan. Tidak dikategorikan sebagai model bisnis. |
| Parsing/decoding/formatting | Folder tugas tersebut, seperti `Markdown/Parsing` dan `ConversationList/Formatting`. |
| Nilai desain | `Tokens/`; `Tokens/Generated` tetap dimiliki export engine. |
| File resource | `Resources/`: font, lisensi, xcassets, dan localization; tidak berisi source Swift. |

Nama folder menjelaskan tugas, bukan hanya bentuk Swift-nya. Tidak semua `struct` masuk
`Models`: `TanyaAIHost` adalah pintu konfigurasi host dan tetap di `Bridging`.
`TanyaAIBridge` adalah pemilik sesi sehingga tetap di root `Session`, bersama extension
implementasi connection/turn. `FontLoader` juga tetap di root fungsi `Typography`.

Extension yang membagi implementasi satu tipe tetap bersama tipe tersebut:
`ChatTableController+Scroll` ada di `Controllers`, dan `MarkdownParser+Inline` di
`Parsing`. Extension accessor/transform yang dipakai caller masuk `Extensions`.
Helper private kecil tetap di file pemilik dengan MARK Helpers/Actions; jangan
membuat satu file atau folder untuk setiap computed property.

Komponen mandiri satu file, seperti `ActionCard`, `RemoteImage`, atau `DateChip`,
tetap langsung di kelompok fungsinya. `ComposerSection` dan `FollowUpsSection` juga
cukup satu file dalam bagian Chat masing-masing. Folder jenis file dipakai pada
pemilik yang memiliki beberapa bagian; tidak perlu membuat folder kosong agar seragam.

## DesignKit

`Components` dibagi berdasarkan fungsi UI: `Actions`, `Images`, `Inputs`, `Lists`,
`Markdown`, `Messages`, dan `Screen`. Komponen beberapa file memiliki folder pemilik,
kemudian `Models`, `Views`, atau jenis lain yang memang dipakai.

Contoh penempatan yang sudah diterapkan:

- `Components/Inputs/MessageComposer/Views/MessageComposer.swift`: susunan composer.
- `Components/Inputs/MessageComposer/Models/MessageComposerAction.swift`: jenis aksi.
- `Components/Inputs/MessageComposer/Extensions/MessageComposerAction+Icon.swift`: pemetaan ikon aksi.
- `Components/Lists/HostedTable/Views/HostingTableViewCell.swift`: cell berisi view SwiftUI.
- `Components/Lists/HostedTable/Controllers/EmbeddedHostingController.swift`: controller khusus containment.
- `Components/Markdown/Models/MarkdownDocument.swift`: Markdown yang sudah di-parse.
- `Components/Markdown/Parsing/MarkdownParser.swift`: parsing dokumen.
- `Components/Markdown/Views/MarkdownContent.swift`: rendering dokumen.
- `Components/Screen/BottomSheet/Models/BottomSheetMaxHeight.swift`: batas tinggi, di bawah status bar atau bagian layar.
- `Components/Screen/BottomSheet/Views/BottomSheet.swift`: permukaan sheet, grabber, dan scroll bila isi melewati batas.
- `Components/Screen/BottomSheet/ViewModifiers/BottomSheetPresenter.swift`: latar gelap, posisi, dan animasi masuk.
- `Components/Screen/BottomSheet/Extensions/View+BottomSheet.swift`: `.bottomSheet(...)`, satu-satunya pintu publiknya.

`Foundations` berisi dukungan lintas komponen: `Typography`, `Iconography`,
`Appearance`, dan `Accessibility`. `Extensions` pada root DesignKit hanya untuk
fungsi kecil lintas komponen: artwork scaling, hex color, locale resource, dan
scroll progress. Service bisnis, validasi rekening, serta flow transfer milik host.

## TanyaAI

| Pemilik | Isi |
| --- | --- |
| `Bridging` | `TanyaAIHost`, kontrak transport host, serta error transport. |
| `Features/Chat/ChatScreen` | Menyusun header, daftar, composer, dan lifecycle halaman. |
| `Chat/Welcome` | `Models` untuk data sambutan; `Views` untuk section welcome. Welcome tetap bagian Chat. |
| `Chat/Composer` | Draft lokal dan callback kirim/stop. |
| `Chat/FollowUps` | Saran pertanyaan berikutnya. |
| `Chat/Messages` | `Models` nilai pesan, `Views` bubble, `Extensions` merge pesan. |
| `Chat/ConversationList` | `Models` item/state/action/input/hari; `Views` baris dan table adapter; `Controllers` table/scroll; `Formatting` tanggal; `Extensions` penyusunan baris. |
| `Chat/Session` | `TanyaAIBridge`, connection/turn, kebijakan backoff, dan `Models` state sesi. |
| `Chat/Gateway` | `Models` kontrak respons/event/history, `Decoding`, `Streaming`, serta metadata protokol. HTTP tetap host. |
| `Chat/Keys` | Key copy, image, identifier, tautan, dan `Extensions` accessor-nya. |
| `Chat/Intents` | `Models/ChatIntent` daftar intent dari gateway. |
| `Chat/Intents/<Nama>` | Satu folder per intent, nama sama dengan case `ChatIntent`. `LiveAgent`: `Models` kartu status, `Extensions` copy kartu, kartu selesai dari history, dan penyisipan kartu ke daftar, `Views` kartu, pesan agen, dan indikator mengetik. |

Saat bagian berbeda membutuhkan model yang sama, letakkan pada pemilik bersama
terdekat. Model khusus Welcome tetap di `Welcome/Models`; model yang benar-benar
lintas bagian Chat boleh di `Chat/Models` saat kebutuhan itu ada. Jangan membuat
satu folder `Models` atau `Views` besar untuk seluruh package.

Urutan kerja saat ini:

```text
Host membuat transport + TanyaAIBridge + TanyaAIHost
    → ChatScreen menjalankan lifecycle sesi
    → Session memanggil transport host: init → history → SSE
    → Gateway decode; Messages menyiapkan nilai pesan dan Markdown
    → ConversationList memperbarui baris berdasarkan ID
    → MessageRow merender dengan komponen DesignKit

Composer / Welcome / FollowUps
    → aksi ke TanyaAIBridge
    → transport host
    → ack/event kembali melalui Session
```

Host membuat bridge sekali selama halaman terbuka. Folder bukan batas module Swift;
`import DesignKit`, `import TanyaAI`, dan API publik tidak berubah karena pemindahan.
Perubahan `onOpenLink` menjadi `String` dan perbaikan back iOS 15 sudah berasal dari
PR #52 di basis `startingpoint`; keduanya dipertahankan pada struktur ini.

## Pola intent

Intent pertama adalah `LiveAgent` (serah terima ke agen manusia). Flow ini digerakkan event gateway,
bukan form host, jadi decode tetap di `Gateway`, state dan aksi `leave-agent` di `Session`
(`TanyaAIBridge+LiveAgent`), dan hanya nilai yang dilihat nasabah di `Intents/LiveAgent`:

```text
TanyaAI/Features/Chat/Intents/LiveAgent/
├── Models/
│   ├── LiveAgentNotice.swift
│   └── LiveAgentNoticeKind.swift
├── Extensions/
│   ├── Array+AgentSession.swift
│   ├── Array+LiveAgentNotice.swift
│   └── LiveAgentNoticeKind+Copy.swift
└── Views/
    ├── AgentTypingIndicator.swift
    ├── LiveAgentMessageRow.swift
    └── LiveAgentNoticeCard.swift
```

Komponen visualnya generik di DesignKit: `NoticeCard`, `SenderMessageCard`, dan `FilledLinkButton`.
Tombol lampiran adalah parameter `attachment` milik `MessageComposer`.

Intent berbentuk flow host, misalnya surat referensi, masih **rancangan, belum keputusan**. Struktur dan
pembagian state di bawah dikonfirmasi ulang saat Figma dan contract flow tersebut tersedia:

```text
TanyaAI/Features/Chat/Intents/ReferenceLetter/
├── Models/
│   ├── ReferenceLetterState.swift
│   ├── ReferenceLetterDraft.swift
│   └── ReferenceLetterSummary.swift
└── Views/
    ├── ReferenceLetterView.swift
    ├── ReferenceLetterFormView.swift
    └── ReferenceLetterSummaryView.swift
```

Host memiliki view model per instance intent yang memegang draft/state dan memakai
use case/service serta coordinator PIN existing. Form mengirim aksi ke host;
hasil final mengubah state instance yang sama menjadi summary. ID baris tetap.
Jenis intent (`referenceLetter`) berbeda dari instance ID karena nasabah dapat
menjalankan jenis flow yang sama beberapa kali.

State hidup bersama owner host, bukan sel table yang dapat di-recycle. Respons
terlambat dicocokkan ke instance/request aktif. Double submit, pembatalan PIN, dan
retry mengikuti use case host. PIN tidak masuk payload TanyaAI atau history.
Riwayat selesai menyimpan snapshot read-only dan tidak menjalankan ulang service.

Slot `makeView { content }` saat ini hanya satu baris sisipan di akhir daftar,
belum penyedia view per intent. Ketika flow pertama dibuat, kontrak item intent
ber-ID stabil dan callback host dirancang bersama kebutuhan flow tersebut.
Tidak perlu BaseIntent, generic flow engine, atau ViewModel untuk setiap komponen.

## Panduan developer berikutnya

1. Tentukan pemilik fungsi: komponen generik DesignKit, bagian Chat, atau bisnis host.
2. Tentukan jenis file dengan tabel di atas. Gunakan folder yang sudah ada bila sesuai.
3. Letakkan data dan helper dekat pemilik; naikkan cakupan hanya bila ada pemakai nyata lain.
4. Ikuti [pola view](VIEW_TEMPLATE.md): input/state, initializer, body, bagian visual,
   kemudian extension Helpers dan Actions. Nama callback menyatakan aksinya.
5. Tests mengikuti pemilik dan jenis perilaku yang diuji. Test yang meliputi beberapa
   jenis file, seperti registrasi dan pemakaian font, tetap di root fungsi tersebut.
   Helper test lintas suite di `Tests/<Package>Tests/Support`.
6. Setelah menambah/memindahkan file, jalankan `Scripts/check_style.sh` dan test yang sesuai.
   Pastikan resource dan test tetap ditemukan.

Pengelompokan folder tidak menambah object, subscription, dependency, atau layer
runtime. Parsing tetap saat data masuk, draft tetap lokal di composer, dan table
memakai ID stabil. Ini bukan benchmark performa; ukur lagi ketika flow baru
memperkenalkan state/proses. Service tidak dimulai dari body/onAppear sel, dan
ketikan form intent harus diamati oleh row pemiliknya.
