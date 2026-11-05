# Service chat di Byon

Kode lengkap sisi host untuk `TanyaAIChatTransport`: init, history, kirim pesan, cancel, dan stream.
Byon tidak ada di repo ini, jadi semua file di bawah **belum dikompilasi**. Yang sudah dijalankan hanya
`StreamLineBuffer` bersama `ServerSentEventParser` asli dari SDK.

## Stream yang datang per bundle

SDK tidak perlu diubah. `events` tetap `AsyncThrowingStream<String, Error>`, dengan syarat satu `String`
adalah satu baris. Bentuk data dari jaringan tidak bisa dijamin, jadi host yang menyusun barisnya.

| Yang masuk ke parser SDK | Hasil untuk 3 frame ditambah komentar |
| --- | --- |
| Satu bundle sebagai satu `String` | 0 event, semua pesan hilang tanpa error |
| Bundle lewat `StreamLineBuffer` | 3 event, urut dan isinya utuh |
| Bundle dipotong di setiap posisi byte (175 posisi), lewat `StreamLineBuffer` | Selalu sama dengan baris di atas, termasuk emoji yang terbelah |

Dengan buffer ini, data datang per baris, per bundle, atau terpotong acak hasilnya sama.

## Urutan copy-paste

| No | File | Aksi | Alasan |
| --- | --- | --- | --- |
| 1 | `BaseService+Method.swift` | Tambah `requestData` dan `refreshAccessToken` | `responseData` menyimpan body mentah, dan refresh yang gagal punya jalur sendiri |
| 2 | `StreamLineBuffer.swift` | Baru | Menyusun potongan stream menjadi baris |
| 3 | `BaseService+SSE.swift` | Ganti seluruh isi | Lolos batas 50 baris; `onEvent` tetap `String` per baris |
| 4 | `TanyaAIChatMode.swift`, `RequestTanyaAIInit.swift`, `RequestTanyaAIHistory.swift`, `RequestTanyaAISendMessage.swift` | Baru | Parameter request tidak di-hardcode |
| 5 | `ChatGatewayService.swift` | Ganti seluruh isi | Path, header, dan pemetaan error ke TanyaAI |
| 6 | `ChatGatewayService+Initialize.swift`, `+History`, `+SendMessage`, `+CancelTurn` | Baru | Satu file per endpoint |
| 7 | `ChatGatewayService+Stream.swift` | Ganti seluruh isi | Meneruskan `onComplete`, mengirim `Last-Event-ID`, memetakan error |
| 8 | `TanyaAIUseCase+Chat.swift` | Ganti seluruh isi | Callback menjadi async sesuai `TanyaAIChatTransport` |
| 9 | View model halaman Tanya AI | Pasang dua callback | Host diberi tahu saat sesi habis dan saat gagal permanen |
| 10 | `ChatGatewayStreamService.swift` | Baru, opsional | Hanya bila stream butuh base URL sendiri |

`NetworkHandler.StreamData` tidak berubah. Parameter `onFailed` di `streamRequest` hilang, karena hasil akhir
stream sekarang dibaca dari `onComplete`.

## 1. `BaseService+Method.swift`

Tambahkan di dalam `extension BaseService`.

```swift
/// Tanpa envelope host: pemanggil menerima respons mentah. Refresh gagal tidak meneruskan 401 lama,
/// karena itu akan dibaca TanyaAI sebagai sesi habis.
func requestData(
    path: String,
    method: HTTPMethod = .get,
    parameters: [String: Any]? = DefaultValues.emptyAnyDictionary,
    headers: HTTPHeaders? = HTTPHeaders(),
    onResponse: @escaping (AFDataResponse<Data>) -> Void,
    onRefreshFailed: @escaping () -> Void
) {
    session = BaseSession()
    attemptCounter += 1
    let data = createRequest(path: path, method: method, parameters: parameters, headers: headers)
    let tracker = DynatraceNetworkTracker(urlString: baseUrl + path)
    tracker.startTracking()
    session.startRequest(data, dynatraceNetworkTracker: tracker)
        .responseData(emptyResponseCodes: [200, 202, 204]) { response in
            tracker.stopTracking(message: response.response?.statusCode.description)
            let isUnauthorized = response.response.map {
                String($0.statusCode) == ErrorCodes.Network.unauthorized
            } ?? false
            guard isUnauthorized, self.attemptCounter < ApiConfig.maximumUnauthorizeRequestAttempt else {
                onResponse(response)
                return
            }
            self.refreshAccessToken(
                onSuccess: {
                    self.requestData(
                        path: path, method: method, parameters: parameters, headers: headers,
                        onResponse: onResponse, onRefreshFailed: onRefreshFailed
                    )
                },
                onFailed: onRefreshFailed
            )
        }
}

private func refreshAccessToken(
    onSuccess: @escaping () -> Void,
    onFailed: @escaping () -> Void
) {
    var request = RequestRetrieveAccessToken()
    request.grantType = .clientCredential
    OAuthService(requestorId).retrieveAccessToken(
        params: request,
        authorization: String(
            format: R.string.format.oauthClientAuthorization.text,
            OAuthConfig.clientId,
            OAuthConfig.clientSecret
        ).toBase64(),
        onSuccess: { data, _ in
            AuthenticationManager.instance.initialize(withResponseRetrieveAccessToken: data)
            onSuccess()
        },
        onFailed: { _, _ in onFailed() }
    )
}
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

```swift
import Alamofire
import Foundation

extension BaseService {
    /// `onEvent` menerima String per baris, berapa pun ukuran potongan dari jaringan.
    /// Arti hasil akhir `completion` ditentukan pemanggil.
    func streamRequest(
        path: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = DefaultValues.emptyAnyDictionary,
        headers: HTTPHeaders? = HTTPHeaders(),
        onEvent: @escaping NetworkHandler.StreamData,
        onComplete: @escaping (DataStreamRequest.Completion) -> Void
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
        // Non-2xx ditutup saat header diterima, jadi body error tidak masuk ke onEvent.
        request.onHTTPResponse(on: .main) { response, completion in
            let successRange = ApiConfig.successCodeBottomLimit..<ApiConfig.successCodeUpperLimit
            completion(successRange.contains(response.statusCode) ? .allow : .cancel)
        }
        // `onChunk` menahan `self`: streamSession ikut mati bila service dilepas.
        let onChunk = lineHandler(onEvent: onEvent)
        request.responseStream(on: .main) { [weak request] stream in
            switch stream.event {
            case let .stream(result):
                guard request?.isCancelled == false, case let .success(chunk) = result else { return }
                onChunk(chunk)
            case let .complete(completion):
                tracker.stopTracking(message: completion.response?.statusCode.description)
                onComplete(completion)
            }
        }
        return request
    }
}

private extension BaseService {
    /// Dipisah agar `var buffer` tidak berada langsung di closure Alamofire, yang bisa `@Sendable`.
    func lineHandler(onEvent: @escaping NetworkHandler.StreamData) -> (Data) -> Void {
        var buffer = StreamLineBuffer()
        return { chunk in
            buffer.append(chunk).forEach { onEvent($0, self.requestorId) }
        }
    }
}
```

## 4. Model request

**`TanyaAIChatMode.swift`**

```swift
/// Tujuan awal percakapan pada init. Nil di request = server memakai `assistant`.
enum TanyaAIChatMode: String {
    case assistant
    case agent
}
```

**`RequestTanyaAIInit.swift`**

```swift
import ObjectMapper

/// Semua field opsional; nilai nil tidak ikut terkirim, jadi default-nya body `{}`.
struct RequestTanyaAIInit: Mappable {
    var mode: TanyaAIChatMode?
    /// Judul awal di daftar percakapan.
    var topic: String?
    /// Pesan pertama. Jangan diisi string kosong, server menjawab 400.
    var message: String?

    init() {}

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        mode <- map["mode"]
        topic <- map["topic"]
        message <- map["message"]
    }
}
```

**`RequestTanyaAIHistory.swift`**

```swift
import ObjectMapper

struct RequestTanyaAIHistory: Mappable {
    var limit = DefaultValues.emptyInt
    /// Nil = halaman terbaru.
    var before: String?

    init() {}

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        limit <- map["limit"]
        before <- map["before"]
    }
}
```

**`RequestTanyaAISendMessage.swift`**

```swift
import ObjectMapper

struct RequestTanyaAISendMessage: Mappable {
    var conversationID = DefaultValues.emptyString
    var clientMessageID = DefaultValues.emptyString
    /// Gateway hanya menerima `text` dari aplikasi.
    var type = "text"
    var payload = DefaultValues.emptyString

    init() {}

    init?(map: Map) {}

    mutating func mapping(map: Map) {
        conversationID <- map["conversation_id"]
        clientMessageID <- map["client_msg_id"]
        type <- map["type"]
        payload <- map["payload"]
    }
}
```

`cancelTurn` tidak punya model, karena endpoint-nya tidak punya field sama sekali.

## 5. `ChatGatewayService.swift`

```swift
import Alamofire
import Foundation
import TanyaAI

class ChatGatewayService: BaseService {
    override var baseUrl: String { ApiConfig.baseUrl + "/v1/chat" }
}

extension ChatGatewayService {
    struct Paths {
        static let streamingEvents = "/conversations/%@/events"
        static let initialize = "/init"
        static let sendMessage = "/messages"
        static let inquiryHistories = "/conversations/%@/messages"
        static let cancelTurn = "/conversations/%@/cancel"
    }

    struct Headers {
        static let lastEventIdentifier = "Last-Event-ID"
    }
}

extension ChatGatewayService {
    /// Body mentah untuk TanyaAI. Non-2xx dilempar beserta body; tanpa status berarti gagal koneksi.
    func requestRawData(
        path: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = DefaultValues.emptyAnyDictionary,
        onSuccess: @escaping TypeAliases.DataHandler,
        onFailed: @escaping (Error) -> Void
    ) {
        requestData(
            path: path,
            method: method,
            parameters: parameters,
            onResponse: { response in
                guard let statusCode = response.response?.statusCode else {
                    onFailed(response.error ?? URLError(.unknown))
                    return
                }
                let body = response.data ?? Data()
                guard (
                    ApiConfig.successCodeBottomLimit..<ApiConfig.successCodeUpperLimit
                ).contains(statusCode) else {
                    onFailed(TanyaAITransportError.response(statusCode: statusCode, body: body))
                    return
                }
                onSuccess(body)
            },
            // URLError = gagal koneksi bagi TanyaAI: retry saat menyambung, bubble gagal saat kirim.
            onRefreshFailed: { onFailed(URLError(.cannotConnectToHost)) }
        )
    }
}
```

## 6. Endpoint

**`ChatGatewayService+Initialize.swift`**

```swift
import Foundation

extension ChatGatewayService {
    func initialize(
        params: RequestTanyaAIInit = RequestTanyaAIInit(),
        onSuccess: @escaping TypeAliases.DataHandler,
        onFailed: @escaping (Error) -> Void
    ) {
        requestRawData(
            path: Paths.initialize,
            method: .post,
            parameters: params.toJSON(),
            onSuccess: onSuccess,
            onFailed: onFailed
        )
    }
}
```

**`ChatGatewayService+History.swift`**

```swift
import Foundation

extension ChatGatewayService {
    func history(
        conversationID: String,
        before: String?,
        limit: Int,
        onSuccess: @escaping TypeAliases.DataHandler,
        onFailed: @escaping (Error) -> Void
    ) {
        var params = RequestTanyaAIHistory()
        params.limit = limit
        params.before = before
        requestRawData(
            path: String(format: Paths.inquiryHistories, conversationID),
            parameters: params.toJSON(),
            onSuccess: onSuccess,
            onFailed: onFailed
        )
    }
}
```

**`ChatGatewayService+SendMessage.swift`**

```swift
import Foundation

extension ChatGatewayService {
    func sendMessage(
        conversationID: String,
        clientMessageID: String,
        text: String,
        onSuccess: @escaping TypeAliases.DataHandler,
        onFailed: @escaping (Error) -> Void
    ) {
        var params = RequestTanyaAISendMessage()
        params.conversationID = conversationID
        params.clientMessageID = clientMessageID
        params.payload = text
        requestRawData(
            path: Paths.sendMessage,
            method: .post,
            parameters: params.toJSON(),
            onSuccess: onSuccess,
            onFailed: onFailed
        )
    }
}
```

**`ChatGatewayService+CancelTurn.swift`**

```swift
import Foundation

extension ChatGatewayService {
    func cancelTurn(
        conversationID: String,
        onSuccess: @escaping TypeAliases.DataHandler,
        onFailed: @escaping (Error) -> Void
    ) {
        requestRawData(
            path: String(format: Paths.cancelTurn, conversationID),
            method: .post,
            onSuccess: onSuccess,
            onFailed: onFailed
        )
    }
}
```

## 7. `ChatGatewayService+Stream.swift`

Tidak ada refresh token di sini, karena setiap reconnect SDK selalu lewat `init` dulu dan `init` sudah
punya refresh. Body error kosong aman: semua error `events` di contract (400, 401, 404, 410, 500, 503)
bisa diputuskan dari status saja.

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
            onComplete: { onComplete(Self.failure(from: $0)) }
        )
    }
}

private extension ChatGatewayService {
    func streamHeaders(lastEventIdentifier: String?) -> HTTPHeaders {
        var headers = HTTPHeaders()
        if let lastEventIdentifier {
            headers.add(name: Headers.lastEventIdentifier, value: lastEventIdentifier)
        }
        return headers
    }

    /// Nil = selesai normal atau dibatalkan; TanyaAI yang memutuskan menyambung ulang.
    static func failure(from completion: DataStreamRequest.Completion) -> Error? {
        let successRange = ApiConfig.successCodeBottomLimit..<ApiConfig.successCodeUpperLimit
        if let statusCode = completion.response?.statusCode, !successRange.contains(statusCode) {
            return TanyaAITransportError.response(statusCode: statusCode, body: Data())
        }
        guard let error = completion.error, !error.isExplicitlyCancelledError else { return nil }
        return error.underlyingError ?? error
    }
}
```

## 8. `TanyaAIUseCase+Chat.swift`

Satu instance service per panggilan, sama seperti `QrisService(identifier)`. `attemptCounter` dan `session`
milik instance, jadi instance bersama bisa me-retry request yang salah.

```swift
import Foundation
import TanyaAI

/// Callback wajib selalu diteruskan: jangan disaring dengan `requestorId`, atau `await` TanyaAI menggantung.
extension TanyaAIUseCase: TanyaAIChatTransport {
    @MainActor
    func initialize() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            ChatGatewayService(identifier).initialize(
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    @MainActor
    func history(conversationID: String, before: String?, limit: Int) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            ChatGatewayService(identifier).history(
                conversationID: conversationID,
                before: before,
                limit: limit,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    @MainActor
    func sendMessage(conversationID: String, clientMessageID: String, text: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            ChatGatewayService(identifier).sendMessage(
                conversationID: conversationID,
                clientMessageID: clientMessageID,
                text: text,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

    @MainActor
    func cancelTurn(conversationID: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            ChatGatewayService(identifier).cancelTurn(
                conversationID: conversationID,
                onSuccess: { continuation.resume(returning: $0) },
                onFailed: { continuation.resume(throwing: $0) }
            )
        }
    }

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
}
```

## 9. View model halaman Tanya AI

Keduanya wajib dipasang. Tanpa `onConnectionFailed`, gagal permanen hanya tampil sebagai halaman kosong.

```swift
@MainActor
private(set) lazy var bridge = TanyaAIBridge(
    transport: useCase,
    onSessionExpired: { NotificationCenter.default.post(name: .unauthorized, object: nil) },
    onConnectionFailed: { [weak self] error in self?.didReceiveError(error) }
)
```

## 10. Opsional: base URL khusus stream

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

## Yang perlu dicek di Byon

- `createRequest` membentuk URL dari `self.baseUrl`, supaya override di langkah 10 berlaku.
- `constructHeader` dengan `isStreamRequest: true` mengirim `Accept: text/event-stream`, sesuai contract.
- `streamRequest` tidak punya pemanggil lain selain chat, karena signature-nya berubah.
- `TypeAliases.DataHandler` adalah `(Data) -> Void`.
