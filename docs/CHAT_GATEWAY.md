# Chat-gateway Tanya AI (contract 1.5.3)

Pembagian kerja host ↔ TanyaAI untuk gateway ICT. Sumber kebenaran contract tetap
`chat-gateway/docs/contract.md` milik BE; dokumen ini hanya menjelaskan bagian yang dipakai iOS.

## Siapa mengerjakan apa

| Host (`TanyaAIChatTransport`) | TanyaAI (`TanyaAIBridge`) |
| --- | --- |
| Base URL, header `X-OCBCNISP-OMNI-SESSION` dan `X-OCBCNISP-OMNI-CHANNEL`, SSL pinning, log | Urutan init → history → SSE dan menyambung ulang |
| Mengirim request per endpoint, mengembalikan body mentah | Decode envelope, `Message`, error, frame SSE |
| Melempar `TanyaAITransportError.response` untuk non-2xx | Retry/backoff, merge history tanpa duplikat |
| Login ulang saat `onSessionExpired` | Bubble pertanyaan langsung, disinkronkan dengan stream; `turn_end` membuka kirim |
| Popup/halaman error saat `onConnectionFailed` | Loading dihentikan, composer nonaktif |

Welcome/shortcut tetap dari BE host (inquiry proposition) dan di-decode host; contract ICT
di-decode TanyaAI karena khusus Tanya AI dan sama di semua host.

## Endpoint yang dipakai

| Fungsi transport | Endpoint |
| --- | --- |
| `initialize()` | `POST /v1/chat/init`, body `{}` |
| `history(conversationID:before:limit:)` | `GET /v1/chat/conversations/{id}/messages?limit=&before=` |
| `sendMessage(conversationID:clientMessageID:text:)` | `POST /v1/chat/messages`, body `{conversation_id, client_msg_id, type:"text", payload}` → 202 |
| `cancelTurn(conversationID:)` | `POST /v1/chat/conversations/{id}/cancel`, tanpa body → 200 `{canceled}` |
| `leaveAgent(conversationID:)` | `POST /v1/chat/conversations/{id}/leave-agent`, tanpa body → 200 `{left}`, 409 bila agen sudah bergabung |
| `attachSuccessID(messageID:successID:)` | `POST /v1/chat/messages/{message_id}/success-id`, body `{"success_id"}` → 200 `{deduplicated}`, 409 bila nilai lain sudah tercatat |
| `events(conversationID:lastEventID:)` | `GET /v1/chat/conversations/{id}/events`, `Accept: text/event-stream`, `Last-Event-ID` bila ada |

Limits, list conversations, dan close belum dipakai.

## Bukti transaksi intent (`success-id`)

`TanyaAIBridge.attachSuccessID(_:toMessageID:)` dipanggil fitur intent setelah transaksinya berhasil di host.
Gateway hanya menerima pesan assistant dengan `action` tidak kosong (selain itu 404), jadi BE harus mengisi `action`
pada pesan intent yang memakainya. Respons 200 langsung menandai pesan (`ChatMessage.successID`) tanpa menunggu
frame dikirim ulang: kiriman ulang tidak ada untuk nilai yang sama dan terlewat bila stream putus setelah
`Last-Event-ID` melewati `seq` pesan. Frame yang dikirim ulang (seq lama) mengganti pesan berdasarkan `message_id`.
History yang dibuka lagi membawa `success_id`, jadi fitur intent membaca `successID` untuk menampilkan kartu
sukses. 401 mengakhiri sesi; error lain dilempar ke pemanggil tanpa menutup percakapan.

## Nilai contract yang dipakai iOS

- `direction`: `user`, `assistant`, `agent`. Nilai lain = `unknown` dan tidak ditampilkan.
- `state`: `ASSISTANT_ACTIVE`, `AGENT_QUEUED`, `AGENT_ACTIVE`, `CLOSED`.
- `type` tidak dibaca. Jawaban `assistant` selalu diproses sebagai Markdown (keputusan user 4 November 2026):
  teks biasa adalah Markdown yang valid. `html` tampil sebagai teks, karena tidak ada HTML renderer.
  Payload objek (`interaction`, `json`) belum punya tampilan dan disembunyikan.
- `intent` dibaca ke `ChatMessage.intent` (`ChatIntent`, daftar intent di `Intents/Models`): `handover-to-agent` =
  `liveAgent`, kosong atau tidak ada = nil, nilai lain = `unknown`. `liveAgent` dibaca untuk kartu "tidak
  dilanjutkan" di history; intent baru ditambah sebagai case saat ada fitur yang memakainya.

## Saran lanjutan

`follow_up_questions` tampil sebagai `SuggestionChip` di bawah jawaban terakhir. Diketuk = terkirim sebagai
pertanyaan lewat `send`, sama seperti shortcut. Saran dari jawaban lama tidak tampil lagi, dan hilang selama
menunggu jawaban. Gagal kirim membuka kunci, jadi saran bisa diketuk lagi.

## Live agent

State percakapan diambil dari init lalu diperbarui event `state`. Selama `AGENT_QUEUED`/`AGENT_ACTIVE`
kirim tidak memakai turn lock karena `turn_end` tidak datang (contract §7.5): nasabah boleh kirim beberapa
pesan dan tombol tidak menjadi stop. Turn bot yang menyerahkan ke agen tetap ditutup `turn_end`-nya sendiri.
Pesan bot di turn itu ("Baik, kami akan menghubungkan...") adalah `Message` assistant biasa dengan
`intent: "handover-to-agent"` (`ChatIntent.liveAgent`) dan `source: ""`; teksnya dari bot dan ikut history.
Aplikasi tidak memakai intent ini: antre/agen ditentukan event `state` dan `system`. Antre lewat init
`mode:"agent"` tidak punya pesan ini.

Event `system` yang menjadi kartu: `agent_connecting` (antre), `agent_ended`, `agent_idle_timeout`,
`queue_canceled`, `queue_timeout`, dan `agent_unavailable`. `agent_joined` tidak punya kartu sendiri: kartu antre
berganti menjadi "Connected to Customer Assistant". `agent_ended` dan `agent_idle_timeout` menjadi kartu "Mode dengan
Customer Assistant Berakhir" (keputusan user 18 November 2026: hanya sesi yang sudah dilayani agen; batal antre, antre
habis, dan agen tidak tersedia tetap kartu lama). Tidak ada chip abu sesi agen (keputusan user 19 November 2026).
`back_to_assistant` selalu bersama event penutup. Copy milik aplikasi; server hanya mengirim token.

Sapaan otomatis (Figma node 3262-86657): sistem agen mengirim pesan `direction: agent` selama `AGENT_QUEUED`, sebelum
agen bergabung. `AGENT_ACTIVE` baru terjadi saat agen benar-benar bergabung (contract §5: `agent` dari
`ParticipantJoined`), jadi pesan agen selama antre dianggap sapaan otomatis. `Message` tidak punya penanda, jadi di
history sapaan tidak bisa dibedakan dari pesan agen biasa; antre yang habis setelah sapaan tampil seperti sesi yang
pernah dilayani (kartu "Connected" lalu kartu selesai) sampai BE memberi penanda. Asumsi ini menunggu konfirmasi BE.

Akhir sesi agen: event `state` dari `AGENT_QUEUED`/`AGENT_ACTIVE` ke state lain menjadi posisi kartu selesai,
karena `id:` berbagi urutan dengan `seq` pesan. Pesan nasabah selama sesi, termasuk yang dikirim sebelum agen manusia
bergabung, tetap di atas kartu. Setelah `leave-agent` menjawab `left:true`, kartu sementara di ujung daftar sampai
event itu tiba. UAT mengirim `system` `agent_left` setelah event `state` saat End Session; token ini belum ada di
contract v1.5.3 sehingga diabaikan dan tidak menambah kartu. Tanpa event `state` (dibuka dari history dan tidak ikut
replay), kartu selesai tetap setelah pesan agen terakhir.

History hanya berisi `Message`, jadi kartu hanya ada selama halaman terbuka. Saat dibuka lagi, kartu yang
`seq`-nya setelah pesan terakhir masih ikut replay SSE (cursor = seq pesan terakhir) selama outbox belum
dipangkas; kartu sebelum pesan terakhir tidak kembali. Pesan agen tetap ada di history (`direction: agent`).

"Batalkan" hanya di kartu antre "Switching to Live Chat with Human", sebelum sapaan otomatis (mengikuti Figma). Setelah
sapaan, antrean dibatalkan lewat End Session di bar sesi agen (keputusan user 20 November 2026; contract mengizinkan
`leave-agent` selama `AGENT_QUEUED`). `left:true` langsung kembali ke bot, kartu batal datang dari stream.
`left:false` atau 409 (agen sudah bergabung) menunggu event `state`.

Selama kartu Switching tampil, composer dikunci (`ComposerSection(isInputEnabled:)` → `MessageComposer`): field abu-abu
dan tidak bisa diketik, keyboard yang masih terbuka ditutup, dan draft tidak bisa dikirim, supaya nasabah tidak mengirim
pesan sebelum tersambung (keputusan user 20 November 2026; tampilan nonaktif umum karena Figma hanya memberi catatan).

Tampilan: kartu status mengikuti Figma frame 62/64 (`NoticeCard` DesignKit: bayangan tanpa garis tepi, ikon headset), tombol batal
`FilledButton` varian `.outlined` di dalam kartu antre, di bawah garis pemisah (slot aksi `NoticeCard`, Figma node
1903-8266), dan pesan agen
mengikuti frame 68 (`SenderMessageCard`: kartu berbayangan, avatar dan label statis "Customer Assistant Tanya OCBC",
teks polos).

Kartu pembuka sesi agen ada satu per sesi:
- Selama antre dan belum ada pesan agen: kartu "Switching" dengan tombol batal, di posisi event antre, atau di akhir
  daftar bila dibuka lagi saat masih antre tanpa event yang ikut replay. Event antre hanya dipakai sebagai posisi bila
  datang setelah jawaban bot terakhir dan belum ditutup event lain.
- Begitu sapaan otomatis datang atau agen bergabung (`agent_joined` bisa mendahului event `state`), kartu yang sama
  berganti menjadi "Connected" tanpa tombol, lalu tetap tampil sebagai riwayat, juga untuk sesi yang ditutup agen
  tanpa pesan. Posisinya event antre sesi itu bila ada dari stream; selain itu tepat sebelum pesan agen pertama, atau
  di posisi `agent_joined`. Sesi berakhir saat bot menjawab, event penutup datang, atau event antre baru datang (event
  penutup lama bisa terlewat bila replay terpangkas), jadi sapaan dari antrean lama bukan milik antrean berikutnya, dan
  event antre yang sudah ditutup tidak dipakai lagi sebagai posisi.
- Event penutup antrean (batal, antre habis, agen tidak tersedia) langsung menyembunyikan kartu antre tanpa menunggu
  event `state`. Acuannya `seq` terakhir yang diketahui saat antrean dimulai: saat event `state` memindahkan ke antre,
  dan setiap init yang masih antre atau dengan agen (antrean, sesi, atau percakapan bisa sudah berganti selama putus),
  atau jawaban bot terakhir bila lebih baru. Di luar antre dan sesi agen acuan ini dilupakan.

Indikator "Mencari customer assistant..." di Figma tidak dibuat: kemampuan itu belum ada di sistem agen (keputusan
user 20 November 2026).

Kartu selesai dari history ditaruh setelah pesan agen terakhir sebuah sesi (sesi berakhir saat bot menjawab lagi, atau
di akhir bila tidak sedang antre atau dilayani agen), kecuali stream sudah memberi kartu penutup untuk sesi itu. Waktu
antre habis dan agen tidak tersedia memakai kartu yang sama. Kartu dari history memakai `seq` pesan yang ditutupnya dan
disisipkan dengan `<=`, jadi tepat setelah pesan itu.
`seq` kartu menjadi id baris table. Bila gateway memberi `id:` SSE dari urutan lain sehingga kartu ber-`seq` sama,
hanya satu yang tampil: kartu pembuka yang sedang berjalan, lalu kartu dari stream, baru kartu turunan history.

Pesan bot ber-intent `handover-to-agent` yang tidak diikuti pesan agen (sampai bot menjawab lagi, atau sampai akhir
daftar bila sudah tidak antre/dilayani dan turn-nya selesai) diberi kartu "tidak dilanjutkan" tepat setelahnya.
History tidak membawa event `system`, jadi penyebabnya (batal, antre habis, agen tidak tersedia) tidak diketahui
dan copy-nya netral. Rentang yang sudah punya kartu dari stream (termasuk kartu antre) tidak diberi kartu ini.
Kartu ini hanya diturunkan dari pesan serah terima yang dimuat lewat history. Pesan serah terima yang datang lewat
stream (termasuk dari kanal lain, atau saat event `state` antre terlambat) ditutup oleh event stream-nya sendiri,
jadi tidak sempat tampil sebagai "tidak dilanjutkan" sebelum event antre tiba. Sinkronisasi history berikutnya
(menyambung ulang) membuat pesan itu kembali dinilai dari history, karena event penutupnya bisa sudah terpangkas.
Tombol batal berwarna #567180 (`CustomColors.Button.muted`).

Nasabah mengetik (§7.7) dikirim lewat `TanyaAIChatTransport.sendTyping` selama `AGENT_QUEUED` dan `AGENT_ACTIVE`;
gateway meneruskannya ke sistem agen (`StartTyping`/`StopTyping`) di kedua state. Composer mengabarkan draft
berisi/kosong; draft tetap lokal. `typing:true` dikirim saat mulai dan diulang paling cepat tiap 5 detik selama terus
mengetik. `typing:false` dikirim setelah 3 detik tanpa ketikan,
saat draft kosong (termasuk setelah terkirim), atau saat composer hilang. Satu pengirim berurutan; sinyal yang
menunggu digabung menjadi yang terbaru dan dicek ulang sebelum dikirim. Saat state meninggalkan agen (lewat init
maupun stream), percakapan berganti, atau sesi berakhir, status dilupakan tanpa kiriman, dan indikator agen
mengetik ikut dihapus. Gagal diabaikan kecuali 401 yang mengakhiri sesi. Balasan ke agen memakai `sendMessage`
yang sama dengan bot; bedanya tidak ada turn lock dan `turn_end`.

Bar hitam "You're now in mode talking with CA" + End Session (`ActionBanner` DesignKit, warna dan ukuran sementara dari
foto Figma) tampil sejak kartu Switching berganti "Connected" (sapaan otomatis, `agent_joined`, atau `AGENT_ACTIVE`),
termasuk selama masih antre, sampai antrean atau sesi agen ditutup; event penutup menyembunyikannya walau event `state`
belum datang (`TanyaAIBridge.isAgentSessionBannerVisible`, keputusan user 20 November 2026). Bar tidak menunggu nama
agen. Bar menempel di bawah header, dan daftar mulai di bawah bar; selama itu header tidak memakai efek scroll (latar,
bayangan, gradient), karena efek itu hanya untuk isi yang lewat di bawah header (keputusan user 20 November 2026). End Session membuka bottom sheet konfirmasi dulu
(Figma node 1903-8266: "Are you sure to exit this mode?" dengan Yes dan No; `ConfirmationPrompt` DesignKit lewat
`ChatSheet.leaveAgent`, Yes sementara `FilledButton` `.regular`). Konfirmasi menyimpan antrean atau sesi saat End Session
diketuk (`AgentSessionKey`: percakapan dan acuan antrean, tanpa state, jadi antre yang berlanjut menjadi dilayani agen
tetap berlaku). Sheet ikut tertutup bila bar hilang atau sesinya berganti (mis. reconnect ke percakapan lain), dan
`leaveAgent(from:)` mengecek ulang tepat sebelum request. Yes memanggil `leave-agent` yang sama dengan Batalkan: `left:true` langsung kembali ke bot, 409 atau gagal lain membuat tombol aktif
lagi. `left:true` yang datang setelah antrean atau sesi tempat request dimulai sudah berganti (state lain atau acuan
antrean baru) diabaikan, jadi antrean berikutnya tidak ikut kembali ke bot; state datang dari stream. Status request
juga terikat ke antrean atau sesi asalnya (`LiveAgentScope`: percakapan, state, acuan antrean): request lama yang masih berjalan tidak mengunci Batalkan
antrean baru, dan selesainya hanya melepas status request itu sendiri.

Selama `AGENT_ACTIVE` composer menampilkan tombol `+` di dalam kartu sebelah kiri field (Figma `typing-area`:
lingkaran 24, garis 1 N200; ikon masih PDF dummy). Ketuk = bottom sheet DesignKit (bukan popover) berisi Galeri
dan File dengan keterangan format, tanpa kamera (keputusan user 18 November 2026; isi sheet sementara `OptionList`
sampai ada Figma). Semua bottom sheet halaman chat (lampiran dan konfirmasi End Session) lewat satu
`.bottomSheet(item:)` di root `ChatScreen` (`ChatSheetModifier` dengan `ChatSheet`); sheet intent form nanti menjadi case
baru di sana. Sheet lampiran dan picker sistem terikat ke sesi agen saat dibuka (`AgentSessionKey`): bila agen berhenti
melayani atau sesinya berganti (mis. reconnect ke percakapan lain yang juga `AGENT_ACTIVE`), keduanya ditutup dan file
dari picker lama dibuang (`ChatSheet.isCurrent`). Galeri memakai `PHPicker` (tanpa izin galeri, representasi asli supaya HEIC tetap HEIC) dan File
memakai document picker `asCopy`. Format hanya PDF, HEIC, JPG/JPEG, dan PNG (`UTType.chatAttachments`); foto galeri
berformat lain (mis. GIF) ditolak: galeri sistem tidak bisa memfilter per format, jadi sheet dibuka lagi dengan pesan
merah (keputusan user; copy sementara). Contract v1.5.3 belum punya endpoint
upload dan parameter preview di stream/history belum pasti, jadi file pilihan nasabah berhenti di
`ChatScreen.attach(_:)` (TODO) dan salinannya langsung dibuang. Selama sheet terbuka, `TanyaAIHost(onSheetChange:)`
memberi tahu host untuk menahan swipe-back. Kartu preview (ikon, nama file, "Lihat Detail") ditunda. Bila endpoint sudah ada: upload lewat
method baru `TanyaAIChatTransport` seperti `leaveAgent`.

Event `typing` dari agen menampilkan "Agen sedang mengetik..." miring di bawah pesan terakhir. Indikator hilang saat
`typing:false`, pesan agen datang, state kembali ke bot, atau `ttl_s` habis tanpa kabar baru (dibaca per frame;
cadangan 5 detik sesuai default `chat.typing_ttl`, contract v1.5.1). Kartu baru dan
indikator mengetik ikut menggeser daftar ke bawah bila pembaca sedang di ujung daftar, sama seperti pesan masuk.

Sandbox `--live-agent`: pertanyaan pertama dijawab bot dengan serah terima ke agen, sapaan otomatis 2 detik setelah
antre, agen bergabung 3 detik kemudian, mengetik lalu menyapa, menjawab pertanyaan berikutnya, lalu menutup percakapan.
End Session selama antre membatalkan antrean; selama dilayani agen mengakhiri sesi. `--hold-greeting` menahan sapaan
dan agen, jadi kartu Switching tetap tampil (UI test composer terkunci).

## Selisih dengan contract 1.5.3 yang belum dikerjakan

- Reconnect selalu lewat init, jadi percakapan yang ditutup admin atau perangkat lain terbuka lagi.
- Pesan `agent` tampil sebagai bubble polos, bukan Markdown.
- 401 langsung ke `onSessionExpired`, sedangkan contract menyarankan init ulang.
- End Session memakai `leave-agent` saat `AGENT_ACTIVE` (aturan baru dari user 19 November 2026), sedangkan contract
  v1.5.3 masih menulis 409 (OQ-P11). Event yang menyusul di stream setelah `left:true` belum dikonfirmasi BE.
- Di UAT, `agent_joined` dan `AGENT_ACTIVE` (`agent: null`) datang sebelum sapaan otomatis dan pesan "masih dalam
  antrian", jadi kartu langsung "Connected" dan bar sesi tampil sedikit sebelum sapaan. Penanda agen manusia yang
  sebenarnya belum dikonfirmasi BE.
- Pesan agen bisa `type: html` (disanitasi gateway); tanpa HTML renderer tag tampil sebagai teks.
- CTA `action` belum tampil; `success_id` sudah dibaca, tetapi kartu suksesnya ikut fitur intent. Copy kartu live agent selain kartu antre masih placeholder.

## Alur

1. Halaman tampil (`.task` di `ChatScreen`): init → history halaman terbaru → buka SSE dengan
   `Last-Event-ID` = `seq` terbesar dari pesan di daftar atau `id` event tersimpan yang sudah diterima
   (`id` typing diabaikan karena typing tidak tersimpan di outbox). Event di antara history dan stream ikut di-replay;
   duplikatnya digabung lewat `message_id`.
2. Stream putus atau error `retryable:true`: jeda 1, 2, 4, … maks 30 detik (atau `retry_after_ms`
   dari 429/503), lalu ulang dari init. History baru diambil per halaman sampai bertemu pesan terakhir
   yang sudah ada, baru sisanya ditambahkan. Jeda kembali ke 1 detik setelah stream tersambung.
3. Berhenti: halaman ditutup (task dibatalkan), init mengembalikan `CLOSED` (history tetap tampil; sejak
   contract 1.4 init resume membuka lagi percakapan `CLOSED`, jadi ini hanya pengaman),
   401 (`onSessionExpired`, sekali), atau error lain dengan `retryable:false` (`onConnectionFailed`, sekali,
   dengan `TanyaAITransportError`). Respons init atau history yang tidak bisa di-decode juga berhenti di sini
   (`onConnectionFailed` dengan `DecodingError`): bentuknya tidak membaik dengan mengulang. Loading awal ikut berhenti. 401 dan gagal permanen dari jalur mana pun
   (termasuk kirim) menutup stream yang sedang terbuka dan bersifat final selama bridge hidup: halaman yang
   tampil lagi (`.task` jalan ulang) tidak menyambung ulang; host membuka halaman baru untuk mencoba lagi.
   Halaman yang hanya tertutup halaman lain lalu tampil lagi tetap menyambung ulang.
4. Kirim (keputusan user 2 November 2026): bubble pertanyaan tampil saat itu juga (`LocalQuestion`) dan
   draft dikosongkan; ack 202 memberi `seq` pertanyaan. Salinan dari stream atau history (dicocokkan lewat
   `client_msg_id`, atau seq ack bila kosong) menggantikan bubble lokal tanpa jeda. Hanya `turn_end` dengan
   `id` lebih besar dari seq pertanyaan yang membuka kunci (replay `turn_end` lama diabaikan; `turn_end`
   sebelum ack dicocokkan saat ack tiba). Kirim gagal = bubble abu-abu dengan hint (`chat.sendFailed`), tanpa
   retry, dan kunci dibuka; bubble gagal tetap di posisinya selama halaman hidup. 401 saat kirim tetap
   `onSessionExpired` dan 404/410 (percakapan hilang) tetap `onConnectionFailed`, sama seperti saat sambung.
   Respons kirim dicocokkan lewat `client_msg_id`: respons yang datang terlambat untuk pertanyaan lama
   (mis. setelah percakapan berganti) tidak mengubah pertanyaan yang sedang ditunggu. 404/410 dari kirim, stop,
   atau `leave-agent` milik percakapan yang sudah diganti init juga tidak menutup percakapan yang baru.
5. Fase composer: tidak ada titik bergerak di composer. Sejak kirim tombol menjadi stop; nasabah boleh mengetik
   pertanyaan berikutnya tetapi harus menekan stop (atau menunggu `turn_end`) untuk mengirimnya. Di daftar, tiga titik
   berdenyut tanpa teks (`TypingDots`; "Sedang menyiapkan jawaban..." hanya label VoiceOver, copy sementara) tampil
   tepat di bawah pertanyaan yang ditunggu sampai jawaban pertama tampil atau kunci terbuka, supaya layar tidak terkesan diam (keputusan user
   19 November 2026). Selama antre atau dilayani agen tidak ada loading ini karena kirim tidak dikunci.
6. Stop: `POST .../cancel`; ditekan sebelum ack = cancel dikirim saat ack tiba (tidak dikirim bila
   kirim gagal). `canceled:true` = kunci tetap sampai `turn_end {"status":"canceled"}` dari
   stream; tombstone pertanyaan (`status:"canceled"`, `message_id` sama) menggantikan pesan aslinya.
   `canceled:false` = gateway tidak punya turn aktif, jadi kunci dibuka langsung karena `turn_end` tidak
   datang. Gagal (selain 401/404/410 yang ditangani seperti kirim) = stop bisa ditekan lagi; cancel idempoten.

Frame SSE selesai di baris `data:` (contract: `data` JSON satu baris dan field terakhir), jadi host
boleh membuang baris kosong tanpa menahan event terakhir.

Percakapan dari init berbeda dengan sebelumnya (yang lama diarsipkan) mengganti daftar.

Tampilan: sebelum history pertama selesai, loading di tengah halaman (reconnect tidak menampilkan
loading; pesan yang sudah tampil tetap terbaca). History kosong = sambutan (greeting, shortcut, emblem);
ada pesan = sambutan disembunyikan. Bubble pertanyaan pertama langsung menggantikan sambutan.
Sementara hanya bubble pertanyaan nasabah yang tampil; bubble bot dan chip tanggal per hari menyusul di PR
daftar pesan.

## Contoh transport di host

Protocol memakai async/await (iOS 15). Host yang service-nya masih callback cukup membungkus
callback dengan continuation; tidak perlu mengubah service lain.
Pola sandbox (dan Byon): UseCase halaman yang conform `TanyaAIChatTransport` lalu memanggil service
callback, lihat [TanyaAIUseCase+Chat](../TanyaAISandboxApp/TanyaAI/TanyaAIUseCase+Chat.swift). Contoh di
bawah menaruh conformance langsung di service; keduanya sama untuk TanyaAI.

Gateway ICT tidak memakai envelope `response_code` host, jadi jangan lewat `BaseService.request`
(`responseJSON` membuang body mentah dan handler-nya memeriksa `response_code`). Buat service baru yang
memakai `Session` Alamofire yang sama (SSL pinning, interceptor) dan `responseData`.

```swift
import Alamofire
import TanyaAI

final class TanyaAIChatService: TanyaAIChatTransport {
    private let session: Session        // session Alamofire host yang sudah ada
    private let baseURL: String         // base URL chat-gateway ICT
    private var headers: HTTPHeaders    // X-OCBCNISP-OMNI-SESSION, X-OCBCNISP-OMNI-CHANNEL, dst.

    func initialize() async throws -> Data {
        try await data(session.request(baseURL + "/v1/chat/init", method: .post,
                                       parameters: [String: String](), encoder: JSONParameterEncoder.default,
                                       headers: headers))
    }

    // history, sendMessage, dan cancelTurn sama: buat DataRequest lalu `try await data(request)`.

    /// Callback Alamofire → async. Non-2xx dilempar beserta body mentah; TanyaAI yang membaca isinya.
    private func data(_ request: DataRequest) async throws -> Data {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                request.responseData(emptyResponseCodes: [200, 202, 204]) { response in
                    let body = response.data ?? Data()
                    if let statusCode = response.response?.statusCode, !(200..<300).contains(statusCode) {
                        continuation.resume(throwing: TanyaAITransportError.response(statusCode: statusCode, body: body))
                    } else {
                        continuation.resume(with: response.result.mapError { $0 as Error })
                    }
                }
            }
        } onCancel: {
            request.cancel()
        }
    }
}
```

SSE lewat `streamRequest` Alamofire (5.2+) agar tetap memakai session yang sama. Satu `String` di
`AsyncThrowingStream` harus satu baris. Jaringan bisa mengirim banyak frame sekaligus atau memutus baris
dan karakter multi-byte di tengah, jadi host menyusun barisnya per byte dengan `StreamLineBuffer`, bukan
`responseStreamString`. Bundle yang langsung dikirim sebagai satu `String` tidak menghasilkan event apa pun.
Kode stream Byon, termasuk `StreamLineBuffer`, ada di [BYON_CHAT_STREAM.md](BYON_CHAT_STREAM.md).

```swift
func events(conversationID: String, lastEventID: String?) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        var headers = self.headers
        headers.add(name: "Accept", value: "text/event-stream")
        if let lastEventID { headers.add(name: "Last-Event-ID", value: lastEventID) }
        let request = session.streamRequest(baseURL + "/v1/chat/conversations/\(conversationID)/events",
                                            headers: headers)
        var buffer = StreamLineBuffer()
        var errorBody = Data()
        request.responseStream { stream in
            let statusCode = request.response?.statusCode ?? 200
            switch stream.event {
            case let .stream(result):
                guard case let .success(chunk) = result else { return }
                guard (200..<300).contains(statusCode) else { errorBody += chunk; return }
                buffer.append(chunk).forEach { continuation.yield($0) }
            case let .complete(completion):
                if !(200..<300).contains(statusCode) {
                    continuation.finish(throwing: TanyaAITransportError.response(statusCode: statusCode,
                                                                                 body: errorBody))
                } else {
                    continuation.finish(throwing: completion.error)
                }
            }
        }
        // Wajib: TanyaAI membatalkan stream saat halaman ditutup atau sesi habis (401).
        continuation.onTermination = { _ in request.cancel() }
    }
}
```

Host tanpa Alamofire bisa memakai `URLSession.bytes(for:)` lalu `for try await line in bytes.lines`
dengan aturan yang sama (non-2xx → `TanyaAITransportError.response`, `onTermination` membatalkan task).
`bytes.lines` membuang baris kosong; parser TanyaAI menutup frame di baris `data:`. Keepalive gateway
menjaga stream tidak kena timeout idle. Jangan log isi pesan.

## Belum diputuskan

- Percakapan baru: belum ada (menu ⋮ dihapus 28 Oktober 2026 karena belum ada kebutuhan).
  Bila dibutuhkan: `X-New-Conversation: true` dibatasi 1 percakapan per CIF (409), jadi perlu close.
- Paging history lebih lama saat scroll ke atas, tampilan pesan `canceled`, payload non-teks, dan
  typing indicator.
