# Stream chat di Byon

Hanya untuk `GET /v1/chat/conversations/{id}/events` (SSE). Endpoint lain sudah ada di Byon.

## Aturan dari SDK

`events` tetap `AsyncThrowingStream<String, Error>`, dan satu `String` harus satu baris. Bentuk data dari
jaringan tidak bisa dijamin, jadi host yang menyusun barisnya.

| Yang masuk ke parser SDK | Hasil |
| --- | --- |
| Satu bundle sebagai satu `String` | 0 event, semua pesan hilang tanpa error |
| Bundle lewat `StreamLineBuffer` | Semua event terbaca, urut dan isinya utuh |
| Bundle terpotong di posisi mana pun, termasuk di tengah emoji | Sama dengan baris di atas |

## Urutan copy-paste

| No | File | Aksi | Alasan |
| --- | --- | --- | --- |
| 1 | `BaseService.HeaderKeys` | Tambah `lastEventId` | Nama header disimpan bersama key lain |
| 2 | `StreamLineBuffer.swift` | Baru | Menyusun potongan stream menjadi baris |
| 3 | `BaseService+SSE.swift`, `BaseService+Method.swift` | Ganti seluruh isi SSE; hapus `private` di `isSuccess` | Lolos batas 50 baris; `onEvent` tetap `String` per baris; body error non-2xx terbaca |
| 4 | `ChatGatewayService+Stream.swift` | Ganti seluruh isi | Mengirim `Last-Event-ID`, meneruskan hasil akhir, memetakan error |
| 5 | `TanyaAIUseCase+Chat.swift` | Ganti fungsi `events` | Callback menjadi `AsyncThrowingStream` |
| 6 | `ChatGatewayStreamService.swift` | Baru, opsional, jangan di-commit | Hanya untuk mock SSE lokal |

`NetworkHandler.StreamData` tidak berubah. Parameter `onFailed` di `streamRequest` hilang, karena hasil akhir
stream dibaca dari `onComplete`.

## 1. `BaseService.HeaderKeys`

`constructHeader` sudah menggabungkan `headers` dari pemanggil, jadi fungsinya tidak perlu diubah.

```swift
static let lastEventId = "Last-Event-ID"
```

## 2. `StreamLineBuffer.swift`

Taruh di `Services/Base`, di samping `BaseService+SSE.swift`.

```swift
import Foundation

/// Menyusun potongan stream menjadi baris utuh. Diproses per byte karena potongan jaringan bisa
/// memutus baris maupun karakter multi-byte di tengah.
struct StreamLineBuffer {
    private static let newline = UInt8(ascii: "\n")
    private var pending = Data()

    mutating func append(_ chunk: Data) -> [String] {
        pending.append(chunk)
        var lines: [String] = []
        while let newlineIndex = pending.firstIndex(of: Self.newline) {
            lines.append(String(decoding: pending[..<newlineIndex], as: UTF8.self))
            pending = Data(pending[pending.index(after: newlineIndex)...])
        }
        return lines
    }
}
```

## 3. `BaseService+SSE.swift`

Non-2xx tidak ditutup lebih awal, supaya body error ikut terbaca. Dari situ SDK mendapat `retryable` dan
`retry_after_ms`, misalnya pada 503 `capacity_full`.

Kode ini memakai `isSuccess(statusCode:)` yang sudah ada di `BaseService+Method.swift`, jadi hapus `private`
di fungsi itu.

```swift
import Alamofire
import Foundation

extension BaseService {
    /// `onEvent` menerima String per baris, berapa pun ukuran potongan dari jaringan.
    /// `onComplete` menerima hasil akhir beserta body error; kosong bila respons 2xx.
    func streamRequest(
        path: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = DefaultValues.emptyAnyDictionary,
        headers: HTTPHeaders? = HTTPHeaders(),
        onEvent: @escaping NetworkHandler.StreamData,
        onComplete: @escaping (DataStreamRequest.Completion, Data) -> Void
    ) -> DataStreamRequest {
        dispatchPrecondition(condition: .onQueue(.main))
        let data = createRequest(
            path: path,
            method: method,
            parameters: parameters,
            headers: headers,
            isStreamRequest: true
        )
        let tracker = DynatraceNetworkTracker(urlString: data.baseUrl + data.path)
        tracker.startTracking()
        let request = streamSession.startStreamRequest(data, dynatraceNetworkTracker: tracker)
        let handleEvent = streamEventHandler(onEvent: onEvent) { completion, errorBody in
            tracker.stopTracking(message: completion.response?.statusCode.description)
            onComplete(completion, errorBody)
        }
        // `self` sengaja tidak weak: streamSession ikut mati bila service dilepas.
        request.responseStream(on: .main) { [self, weak request] stream in
            let statusCode = request?.response?.statusCode ?? ApiConfig.successCodeBottomLimit
            handleEvent(stream.event, isSuccess(statusCode: statusCode))
        }
        return request
    }
}

private extension BaseService {
    /// Dipisah agar `var` tidak berada langsung di closure Alamofire, yang bisa `@Sendable`.
    func streamEventHandler(
        onEvent: @escaping NetworkHandler.StreamData,
        onComplete: @escaping (DataStreamRequest.Completion, Data) -> Void
    ) -> (DataStreamRequest.Event<Data, Never>, Bool) -> Void {
        var lineBuffer = StreamLineBuffer()
        var errorBody = Data()
        return { event, isSuccess in
            switch event {
            case let .stream(result):
                guard case let .success(chunk) = result else { return }
                guard isSuccess else {
                    errorBody.append(chunk)
                    return
                }
                lineBuffer.append(chunk).forEach { onEvent($0, self.requestorId) }
            case let .complete(completion):
                onComplete(completion, errorBody)
            }
        }
    }
}
```

## 4. `ChatGatewayService+Stream.swift`

Tidak ada refresh token di sini, karena setiap reconnect SDK selalu lewat `init` dulu dan `init` sudah
punya refresh.

```swift
import Alamofire
import Foundation
import TanyaAI

extension ChatGatewayService {
    func streamingEvents(
        conversationIdentifier: String,
        lastEventIdentifier: String?,
        onLine: @escaping (String) -> Void,
        onComplete: @escaping (Error?) -> Void
    ) -> DataStreamRequest {
        streamRequest(
            path: String(format: Paths.streamingEvents, conversationIdentifier),
            method: .get,
            headers: streamHeaders(lastEventIdentifier: lastEventIdentifier),
            onEvent: { line, _ in onLine(line) },
            onComplete: { completion, errorBody in
                onComplete(self.failure(from: completion, errorBody: errorBody))
            }
        )
    }
}

private extension ChatGatewayService {
    func streamHeaders(lastEventIdentifier: String?) -> HTTPHeaders {
        var headers = HTTPHeaders()
        if let lastEventIdentifier {
            headers.add(name: BaseService.HeaderKeys.lastEventId, value: lastEventIdentifier)
        }
        return headers
    }

    /// Nil = selesai normal atau dibatalkan; TanyaAI yang memutuskan menyambung ulang.
    func failure(from completion: DataStreamRequest.Completion, errorBody: Data) -> Error? {
        if let statusCode = completion.response?.statusCode, !isSuccess(statusCode: statusCode) {
            return TanyaAITransportError.response(statusCode: statusCode, body: errorBody)
        }
        guard let error = completion.error, !error.isExplicitlyCancelledError else { return nil }
        return error.underlyingError ?? error
    }
}
```

## 5. `TanyaAIUseCase+Chat.swift`

Ganti fungsi `events`.

```swift
/// Tanpa `@MainActor`, karena requirement-nya sinkron. `TanyaAIBridge` selalu memanggilnya dari main actor,
/// jadi `dispatchPrecondition` di `streamRequest` tetap terpenuhi.
func events(conversationID: String, lastEventID: String?) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        let request = ChatGatewayService(identifier).streamingEvents(
            conversationIdentifier: conversationID,
            lastEventIdentifier: lastEventID,
            onLine: { continuation.yield($0) },
            onComplete: { continuation.finish(throwing: $0) }
        )
        // Wajib: TanyaAI menutup stream saat halaman ditutup atau sesi habis.
        continuation.onTermination = { _ in request.cancel() }
    }
}
```

## 6. Opsional: mock SSE lokal

Hanya untuk testing, jadi file dan perubahan di langkah ini jangan di-commit ke Byon.

Mockoon belum mendukung SSE, jadi stream dilayani [`Scripts/mock_gateway.py`](../Scripts/mock_gateway.py) di
port 3001. Mockoon tetap di port 3000 untuk service biasa.

| Service | Tujuan |
| --- | --- |
| Login, `init`, history, service lain | Mockoon `localhost:3000` |
| `events`, `sendMessage`, `cancelTurn` | Skrip `localhost:3001` |

`sendMessage` ikut ke skrip karena dari situlah skrip tahu ada pertanyaan. Setelah menerimanya, skrip mengirim
echo pertanyaan, jawaban 5 detik kemudian, lalu `turn_end` lewat stream. `cancelTurn` ikut ke skrip karena hanya
skrip yang bisa menghentikan jawaban: stream mengirim tombstone pertanyaan lalu `turn_end` canceled, tanpa jawaban.
Seq dimulai dari 1001, jadi seq di history Mockoon harus lebih kecil.

```bash
python3 Scripts/mock_gateway.py
```

Buat `ChatGatewayStreamService.swift`. Kelasnya turunan `ChatGatewayService`, jadi semua fungsi ikut, dan yang
berbeda hanya `baseUrl` sesuai instance yang dibuat.

```swift
/// Hanya untuk mock lokal; jangan di-commit.
final class ChatGatewayStreamService: ChatGatewayService {
    override var baseUrl: String {
        #if DEBUG
        return "http://localhost:3001/v1/chat"
        #else
        return super.baseUrl
        #endif
    }
}
```

Di `TanyaAIUseCase+Chat.swift`, ganti `ChatGatewayService(identifier)` menjadi
`ChatGatewayStreamService(identifier)` hanya di `sendMessage`, `events`, dan `cancelTurn`.

### Satu flow mock

Semua id di bawah sudah sama dalam satu flow. Conversation id: `6ba7b810-9dad-41d1-80b4-00c04fd430c8`.

#### 1. Init

`POST http://localhost:3000/v1/chat/init`, status 200:

```json
{
  "success": true,
  "data": {
    "conversation_id": "6ba7b810-9dad-41d1-80b4-00c04fd430c8",
    "state": "ASSISTANT_ACTIVE"
  }
}
```

#### 2. History

`GET http://localhost:3000/v1/chat/conversations/6ba7b810-9dad-41d1-80b4-00c04fd430c8/messages`, status 200:

```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "message_id": "h-2",
        "seq": "2",
        "direction": "assistant",
        "type": "markdown",
        "payload": "Halo, **ada yang bisa dibantu?**",
        "follow_up_questions": ["Berapa total investasi aku?"],
        "client_msg_id": null,
        "status": "active",
        "created_at": "2026-11-05T09:00:05+07:00"
      },
      {
        "message_id": "h-1",
        "seq": "1",
        "direction": "user",
        "type": "text",
        "payload": "Halo",
        "follow_up_questions": null,
        "client_msg_id": "c-0001",
        "status": "active",
        "created_at": "2026-11-05T09:00:00+07:00"
      }
    ],
    "next_before": null
  }
}
```

#### 3. Stream

`GET http://localhost:3001/v1/chat/conversations/6ba7b810-9dad-41d1-80b4-00c04fd430c8/events`, status 200, header
`Content-Type: text/event-stream`, koneksi tetap terbuka:

```text
: connected

```

#### 4. Kirim pesan

`POST http://localhost:3001/v1/chat/messages`, status 202:

```json
{"success": true, "data": {"message_id": "m-1001", "seq": "1001"}}
```

Isi stream sampai selesai:

```text
id: 1001
event: message
data: {"message_id": "m-1001", "seq": "1001", "direction": "user", "type": "text", "payload": "Cek portofolio", "status": "active", "client_msg_id": "c-0002", "created_at": "2026-11-05T10:00:00+07:00"}

id: 1002
event: message
data: {"message_id": "m-1002", "seq": "1002", "direction": "assistant", "type": "text", "payload": "**Jawaban mock** untuk: Cek portofolio", "status": "active", "client_msg_id": null, "created_at": "2026-11-05T10:00:05+07:00"}

id: 1003
event: turn_end
data: {"status": "completed", "active_turn_id": null}

```

#### 5. Kirim pesan kedua, lalu stop

`POST http://localhost:3001/v1/chat/messages`, status 202:

```json
{"success": true, "data": {"message_id": "m-1004", "seq": "1004"}}
```

Isi stream setelah kirim:

```text
id: 1004
event: message
data: {"message_id": "m-1004", "seq": "1004", "direction": "user", "type": "text", "payload": "Beli valas", "status": "active", "client_msg_id": "c-0003", "created_at": "2026-11-05T10:01:00+07:00"}

```

`POST http://localhost:3001/v1/chat/conversations/6ba7b810-9dad-41d1-80b4-00c04fd430c8/cancel`, tanpa body, status 200:

```json
{"success": true, "data": {"canceled": true}}
```

Isi stream setelah cancel:

```text
id: 1004
event: message
data: {"message_id": "m-1004", "seq": "1004", "direction": "user", "type": "text", "payload": "Beli valas", "status": "canceled", "client_msg_id": "c-0003", "created_at": "2026-11-05T10:01:00+07:00"}

id: 1005
event: turn_end
data: {"status": "canceled", "active_turn_id": null}

```

#### Yang perlu dibuat

- Mockoon: langkah 1 dan 2 saja.
- Skrip `mock_gateway.py`: langkah 3, 4, dan 5 otomatis, jadi tidak perlu di-copy manual.
- Kalau stream ditulis sendiri tanpa skrip: `client_msg_id` harus sama dengan yang dikirim SDK di request, karena SDK
  membuat nilainya sendiri. `c-0002` dan `c-0003` di atas hanya contoh.

## Yang sudah diuji

Kode di dokumen ini dikompilasi dengan Alamofire 5.12.2 dan dijalankan di macOS terhadap server SSE lokal.
`BaseService`, `createRequest`, dan `startStreamRequest` memakai tiruan, jadi kode asli Byon belum ikut teruji.

| Skenario | Hasil |
| --- | --- |
| Potongan berakhir di tengah emoji, sisanya bundle banyak frame | Semua event terbaca di parser SDK, stream selesai bersih |
| `lastEventID` terisi | Server menerima `Last-Event-ID` |
| 503 dengan body | `TanyaAITransportError` beserta body, termasuk `retry_after_ms` |
| 401 tanpa body, 410 dengan body | `TanyaAITransportError` dengan status yang benar |
| Stream dibatalkan | Koneksi di server terputus, tanpa error, tracker berhenti |
| Stream selesai atau dibatalkan | Service dilepas dari memori, tidak ada retain cycle tersisa |
| Server tidak bisa dihubungi | Error koneksi diteruskan, SDK me-retry |

## Yang perlu dicek di Byon

- `streamRequest` tidak punya pemanggil lain selain chat, karena signature-nya berubah.
- Bridge memasang `onSessionExpired` dan `onConnectionFailed`, karena error stream berakhir di sana.
