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

Komponen mandiri satu file, seperti `ActionCard`, `RemoteImage`, atau `TextChip`,
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
- `Components/Inputs/FormField/Views/`: `SelectField` (membuka daftar pilihan), `TextInputField`, `ToggleRow`, dan
  `FieldFrame` (label, isi, error merah) yang dipakai bersama; kotak field di `ViewModifiers/FieldBox.swift` (padding
  di atas `cardStyle`).
- `Components/Lists/OptionList/`: isi sheet daftar pilihan (`OptionList`), satu atau banyak pilihan, dengan state loading.
- `Components/Inputs/PinEntry/`: isi sheet PIN (`PinEntry`): `Models/PinPadKey` susunan keypad dan aturan input,
  `Views` titik, tombol keypad, dan `PinEntry`.
- `Components/Actions/FilledButton.swift`: tombol selebar wadah; `.regular` (Konfirmasi, Pilih), `.outlined` (aksi
  kedua bergaris seukuran `.regular`, mis. Batalkan di form), dan `.link` (teks kecil bergaris bawah, mis. "Batalkan
  proses ini").
- `Components/Feedback/LoadingIndicator.swift`: spinner untuk semua loading.
- `Components/Lists/SeparatorLine.swift`: garis pemisah 1 pt (daftar, tabel Markdown, di atas composer).
- `Components/Screen/BottomSheet/Models/BottomSheetMaxHeight.swift`: batas tinggi, di bawah status bar atau bagian layar.
- `Components/Screen/BottomSheet/Models/BottomSheetLayout.swift`: batas tinggi dan letak sheet dari safe area, layar
  tanpa notch, dan keyboard.
- `Components/Screen/BottomSheet/Views/BottomSheet.swift`: permukaan sheet, grabber, scroll bila isi melewati batas,
  footer yang menempel, dan kunci tutup.
- `Components/Screen/BottomSheet/ViewModifiers/BottomSheetPresenter.swift`: latar gelap, posisi, animasi masuk, dan
  mengikuti keyboard (`Extensions/Notification+KeyboardTop.swift`).
- `Components/Screen/BottomSheet/Extensions/View+BottomSheet.swift`: `.bottomSheet(isPresented:)`,
  `.bottomSheet(item:)`, dan `.bottomSheetFooter`, satu-satunya pintu publiknya; `Binding+Presence.swift` mengubah
  nilai optional menjadi ada/tidaknya sheet.
- Footer yang menempel: `ViewModifiers/BottomSheetFooterModifier.swift` menitipkan footer lewat
  `Models/BottomSheetFooterKey.swift`; `Models/BottomSheetFooterPlacement.swift` dan
  `Extensions/EnvironmentValues+BottomSheet.swift` memberi tahu isi bahwa ia berada di dalam sheet.
- `Foundations/Typography/Models/DesignFontRole.swift`: peran teks (face + ukuran);
  `Extensions/View+DesignFont.swift` = `.designFont(role)`.

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
| `Chat/Session` | `TanyaAIBridge`, connection/turn, kebijakan backoff, dan `Models` state sesi (`ChatTurn`, `UserTypingSignal`). |
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

Komponen visualnya generik di DesignKit: `NoticeCard`, `SenderMessageCard`, dan `FilledButton` varian `.link`.
Tombol lampiran adalah parameter `attachment` milik `MessageComposer`.

### Menambah intent: langkah yang sudah punya pola

Ikuti `LiveAgent`. Daftar ini urut dari data ke tampilan; hampir semuanya dijaga compiler karena berupa `switch`
tanpa `default`, jadi case baru yang belum ditangani gagal di-build, bukan diam-diam tidak tampil.

| # | Yang ditambah | Tempat | Contoh di `LiveAgent` |
| --- | --- | --- | --- |
| 1 | Case intent dengan nilai gateway-nya | `Intents/Models/ChatIntent.swift` | `liveAgent = "handover-to-agent"` |
| 2 | Folder intent, nama sama dengan case | `Intents/<Nama>/{Models,Extensions,Views}` | `Intents/LiveAgent` |
| 3 | Bentuk data dari gateway (bila ada event atau field baru) | `Gateway/Models` + case di `ChatEvent` | `WireSystemNotice`, `ChatEvent.notice` |
| 4 | State dan aksi sesi | Satu file `Session/TanyaAIBridge+<Nama>.swift`; state-nya satu value type | `TanyaAIBridge+LiveAgent`, `UserTypingSignal` |
| 5 | Endpoint chat-gateway baru (bila ada) | Method di `TanyaAIChatTransport`; service milik host tidak di sini (lihat intent form di bawah) | `leaveAgent`, `sendTyping` |
| 6 | Baris di daftar chat | Case di `ChatListItem` dan `ChatListItemID`, jarak di `topSpacing`, tampilan di `ChatListRow` | `liveAgentNotice`, `leaveAgentQueue`, `agentTyping` |
| 7 | Posisi baris di antara pesan | Extension di `Intents/<Nama>/Extensions`, dipanggil dari `ChatScreen.listItems` | `Array+LiveAgentNotice` |
| 8 | Aksi dari baris | Closure di `ChatRowActions`, penerusnya di `ChatTableController.forwardingActions`, isinya di `ChatScreen.rowActions` | `onLeaveAgentQueue` |
| 9 | Tampilan | `Intents/<Nama>/Views`, disusun dari komponen DesignKit | `LiveAgentNoticeCard` memakai `NoticeCard` |
| 10 | Copy dan identifier | Case `ChatCopy` + tiga `Localizable.strings`; `ChatElementIdentifier` | `liveAgent.*` |
| 11 | Test dan contoh | Test mencerminkan Sources; mode sandbox + UI test; frame di `Scripts/mock_gateway.py` | `--live-agent` |

Aturan yang berlaku untuk semua intent:

- State sesi berupa value type yang bisa dites sendiri (`ChatTurn`, `UserTypingSignal`); `TanyaAIBridge` hanya
  memegang satu properti per state dan menjalankan efeknya (kirim, pewaktu). Jangan menambah deretan `Bool` lepas.
- `seq` atau id dari gateway yang dijadikan id baris harus dijaga unik sebelum sampai ke table: table crash bila
  menerima id ganda (lihat `visibleLiveAgentNotices` dan `[ChatListItem](rows:)`).
- Tampilan intent tidak memegang state yang harus bertahan: sel table dipakai ulang, jadi state hidup di luar sel.
- Komponen yang dipakai intent kedua pindah ke DesignKit dengan nama generik; yang sekali pakai tetap di folder intent.

### Intent berbentuk form: yang sudah diputuskan dan yang belum dibangun

Keputusan user 12 November 2026 untuk `request-bank-reference-letter` dan `buy-mutual-funds`; ini menggantikan
rancangan lama (view model per intent di host, coordinator PIN existing):

- Satu mesin form di TanyaAI untuk semua intent form; per intent hanya definisi field dan pemetaannya ke request
  host. Jenis field: pilihan lewat bottom sheet (satu atau banyak), teks (termasuk nominal dan email), dan toggle.
- Field bisa bergantung pada field lain; field yang disembunyikan di-reset. Field nonaktif bebas validasi.
- Validasi hanya saat Konfirmasi: teks kosong = error merah di bawahnya; pilihan kosong paling atas = sheet-nya
  langsung terbuka.
- Daftar pilihan dan service (submit, PIN) milik host; sheet punya state loading selama host mengambil data.
- Tombol Batalkan + Konfirmasi. Konfirmasi membuka sheet PIN: keypad di package, angkanya diteruskan ke host,
  tidak disimpan atau di-log. PIN salah = sheet tetap terbuka dengan error dari host.
- Selesai atau batal menjadi kartu status; di history cukup kartu "pernah request" dari `intent` pesan bot.

Komponennya sudah ada di DesignKit (`SelectField`, `TextInputField`, `ToggleRow`, `FilledButton`, `OptionList`,
`PinEntry`, `.bottomSheet(item:)`); contoh susunannya di sandbox `--form-demo`, termasuk sheet PIN setelah Konfirmasi. Tiga hal di bawah **belum punya pola di kode**,
karena `LiveAgent` tidak membutuhkannya. Ketiganya dirancang bersama intent form pertama, bukan disiapkan kosong:

| Belum ada | Kenapa belum | Arah yang sudah disepakati |
| --- | --- | --- |
| State form per instance | `LiveAgent` hanya punya satu state per percakapan | Di TanyaAI, di luar sel table, dengan id instance = id pesan pemicunya |
| Sheet yang dibuka dari baris chat | Belum ada baris yang membuka sheet | `.bottomSheet(item:)` di root `ChatScreen`; package memberi tahu host saat sheet terbuka supaya swipe-back ditahan |
| Data dan service dari host | Transport sekarang hanya untuk chat-gateway | Satu protocol per intent, terpisah dari `TanyaAIChatTransport`; rancangannya di bawah |

### Rancangan struktur intent form

Disepakati user 16 November 2026. Belum ada di kode: dibangun di PR intent form pertama (surat referensi), dan nama
tipe boleh berubah saat itu. `LiveAgent` tidak mengikuti rancangan ini karena flow-nya digerakkan event gateway.

**Service host tidak lewat `TanyaAIChatTransport`.** Transport hanya untuk endpoint chat-gateway: mengembalikan
`Data` mentah yang di-decode TanyaAI, dan error koneksinya diulang otomatis. Service Byon (daftar rekening, submit,
PIN) punya model dan error sendiri yang sudah ada di host, dan submit atau PIN tidak boleh diulang otomatis. Endpoint
chat-gateway baru untuk sebuah intent (seperti `leaveAgent`) tetap masuk transport.

Dibuat sekali, bersama intent form pertama:

```text
TanyaAI/Bridging/
└── TanyaAIIntentServices.swift        // struct publik: satu properti opsional per service intent

TanyaAI/Features/Chat/Intents/Form/    // mesin bersama, bukan intent
├── Models/                            // jenis field, nilai form, state per instance, status
├── Extensions/                        // validasi saat Konfirmasi, dependensi dan reset field anak
└── Views/                             // kartu form, isi sheet (OptionList, PinEntry), kartu selesai/batal

TanyaAI/Features/Chat/Session/
└── TanyaAIBridge+Form.swift           // state form per id pesan, buka sheet, alur submit dan PIN
```

Bridge menerimanya lewat `TanyaAIBridge(transport:services:)` dengan `services` opsional, jadi host yang belum
memakai intent form tidak berubah. Intent yang service-nya tidak diberikan host tidak menampilkan form.

Per intent, contoh surat referensi:

```text
TanyaAI/Features/Chat/Intents/ReferenceLetter/
├── Protocols/
│   └── ReferenceLetterService.swift            // publik, diimplementasikan host
├── Models/
│   ├── ReferenceLetterFieldID.swift            // enum id field
│   └── ReferenceLetterRequest.swift            // publik, nilai bertipe yang dikirim ke host
└── Extensions/
    ├── ReferenceLetterFieldID+Definition.swift // daftar field, jenis, default, dependensi
    └── ReferenceLetterRequest+Values.swift     // nilai form menjadi request
```

```swift
public protocol ReferenceLetterService: AnyObject {
    func accounts() async throws -> [ReferenceLetterAccount]
    func submit(_ request: ReferenceLetterRequest, pin: String) async throws
}
```

Di luar folder intent hanya beberapa baris: case `ChatIntent`, properti di `TanyaAIIntentServices`, copy di
`ChatCopy` dan tiga `Localizable.strings`, lalu test, service tiruan sandbox, dan UI test. Folder `Views/` per intent
hanya dibuat bila intent butuh tampilan yang tidak ada di mesin, misalnya kartu produk reksa dana.

Alasan bentuknya:

- Protocol di folder intent, bukan di `Bridging`: menambah intent cukup menyalin satu folder. `public` tidak
  bergantung pada letak folder, dan `Protocols/` sudah termasuk jenis folder yang diizinkan.
- Protocol bertipe, bukan dictionary `[String: Any]`: pemetaan field ke request dicek compiler, dan host tinggal
  memanggil service yang sudah ada.
- Wadah `TanyaAIIntentServices`: init bridge tidak bertambah panjang setiap ada intent.
- PIN hanya diteruskan ke host dalam satu pemanggilan, tidak disimpan atau di-log package.

Diputuskan saat membangun, dari request surat referensi yang sebenarnya:

- PIN ikut `submit` (seperti contoh di atas), atau service PIN bersama bila di host cek PIN adalah langkah terpisah.
- Bentuk error dari host ke package, supaya pesan seperti "PIN salah" tampil di sheet.

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
