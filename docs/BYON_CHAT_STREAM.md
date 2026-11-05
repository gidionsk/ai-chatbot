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
| 6 | `ChatGatewayStreamService.swift` | Baru, opsional | Hanya bila stream butuh base URL sendiri |

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

## 6. Opsional: base URL khusus stream

Satu port bisa melayani SSE dan POST bersamaan, jadi ini hanya perlu bila memang ada dua server. Kalau POST
macet saat SSE terbuka di server lokal, penyebabnya biasanya server single-thread: SSE memakai satu-satunya
worker. Perbaiki servernya lebih dulu, misalnya `ThreadingHTTPServer` di Python atau `threaded=True` di Flask.

Kalau tetap perlu, buat `ChatGatewayStreamService.swift`, lalu isi `ApiConfig.chatStreamBaseUrl` per
environment dan samakan dengan `ApiConfig.baseUrl` di luar lokal.

```swift
/// Stream dengan base URL sendiri; endpoint lain tetap lewat `ChatGatewayService`.
final class ChatGatewayStreamService: ChatGatewayService {
    override var baseUrl: String { ApiConfig.chatStreamBaseUrl + "/v1/chat" }
}
```

Di `events`, ganti `ChatGatewayService(identifier)` menjadi `ChatGatewayStreamService(identifier)`.

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
