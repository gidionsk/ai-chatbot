# Chat-gateway Tanya AI (contract 1.5.0)

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
| `events(conversationID:lastEventID:)` | `GET /v1/chat/conversations/{id}/events`, `Accept: text/event-stream`, `Last-Event-ID` bila ada |

Typing, limits, list conversations, close, leave-agent, dan `success-id` belum dipakai.

## Nilai contract yang dipakai iOS

- `direction`: `user`, `assistant`, `agent`. Nilai lain = `unknown` dan tidak ditampilkan.
- `state`: `ASSISTANT_ACTIVE`, `AGENT_QUEUED`, `AGENT_ACTIVE`, `CLOSED`.
- `type` tidak dibaca. Jawaban `assistant` selalu diproses sebagai Markdown (keputusan user 4 November 2026):
  teks biasa adalah Markdown yang valid. `html` tampil sebagai teks, karena tidak ada HTML renderer.
  Payload objek (`interaction`, `json`) belum punya tampilan dan disembunyikan.

## Selisih dengan contract 1.5.0 yang belum dikerjakan

- `AGENT_*` tanpa turn lock dan `turn_end`: setelah kirim, tombol tertahan di stop sampai ditekan.
- Reconnect selalu lewat init, jadi percakapan yang ditutup admin atau perangkat lain terbuka lagi.
- Pesan `agent` tampil sebagai bubble polos, bukan Markdown.
- 401 langsung ke `onSessionExpired`, sedangkan contract menyarankan init ulang.
- `follow_up_questions`, CTA `action` dan `success-id`, serta event `typing`, `system`, `state` belum tampil.

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
   dengan `TanyaAITransportError`). Loading awal ikut berhenti. 401 dari jalur mana pun (termasuk kirim)
   menutup stream yang sedang terbuka dan bersifat final: tidak menyambung ulang.
4. Kirim (keputusan user 2 November 2026): bubble pertanyaan tampil saat itu juga (`LocalQuestion`) dan
   draft dikosongkan; ack 202 memberi `seq` pertanyaan. Salinan dari stream atau history (dicocokkan lewat
   `client_msg_id`, atau seq ack bila kosong) menggantikan bubble lokal tanpa jeda. Hanya `turn_end` dengan
   `id` lebih besar dari seq pertanyaan yang membuka kunci (replay `turn_end` lama diabaikan; `turn_end`
   sebelum ack dicocokkan saat ack tiba). Kirim gagal = bubble abu-abu dengan hint (`chat.sendFailed`), tanpa
   retry, dan kunci dibuka; bubble gagal tetap di posisinya selama halaman hidup. 401 saat kirim tetap
   `onSessionExpired` dan 404/410 (percakapan hilang) tetap `onConnectionFailed`, sama seperti saat sambung.
   Respons kirim dicocokkan lewat `client_msg_id`: respons yang datang terlambat untuk pertanyaan lama
   (mis. setelah percakapan berganti) tidak mengubah pertanyaan yang sedang ditunggu.
5. Fase composer: tidak ada titik bergerak. Sejak kirim tombol menjadi stop; nasabah boleh mengetik
   pertanyaan berikutnya tetapi harus menekan stop (atau menunggu `turn_end`) untuk mengirimnya.
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
Kode lengkap Byon, termasuk `StreamLineBuffer`, ada di [BYON_CHAT_SERVICE.md](BYON_CHAT_SERVICE.md).

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
