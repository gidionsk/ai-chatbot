# Membuka Tanya AI dari host app

Tanya AI adalah halaman SwiftUI biasa: `TanyaAIHost.makeView()` ditampilkan oleh
navigasi milik host, dan halaman berikutnya juga milik host. Package tidak membuat
modal, animasi, navigation stack, service, atau aturan bisnis sendiri, sehingga
API yang sama dipakai oleh host SwiftUI saat ini maupun aplikasi revamp nanti.

## Package dan font

Tambahkan product `TanyaAI` ke target host. Jika host memanggil API font atau token
secara langsung, tambahkan juga product `DesignKit` dari package yang sama dengan
dependency TanyaAI, agar tidak ada dua salinan package/token/font.

Daftarkan font sekali di `application(_:didFinishLaunchingWithOptions:)`:

```swift
import DesignKit

do { try FontFace.registerFonts() } catch { /* log milik host */ }
```

Font dibaca dari `Bundle.module` DesignKit; host tidak perlu menyalin file font atau
menambahkannya ke `UIAppFonts`. Daftar face ada di
[katalog font](../Packages/DesignKit/Sources/DesignKit/Resources/Fonts/SOURCES.md).

## 1. Host SwiftUI saat ini: coordinator + destination

Tanya AI didaftarkan seperti fitur lain: `NavigationLink(tag:selection:)` di coordinator
yang punya pintu masuk Tanya AI. View model halaman dipegang `@StateObject` di view
tujuan (`TanyaAIDestination`), sehingga dibuat sekali saat halaman di-push, dilepas saat
di-pop, dan tidak ikut dibuat ulang ketika halaman induk render ulang. Halaman dibungkus
base `Screen` host, jadi blocker per halaman dan blocker root tetap tampil di atasnya.

Data mengikuti matriks Input/Output/Repository host: coordinator menulis Input, UseCase mengolah
Input ke Repository, view model hanya membaca Repository. UseCase halaman Tanya AI sekaligus menjadi
`TanyaAIChatTransport` (hit API lewat service callback yang dibungkus continuation). Contoh berikut memakai
UseCase yang sama untuk menyediakan `TanyaAIHostServices` lewat parameter `hostServices:`.

```
UseCase induk: inquiry → output.greeting/shortcuts → callback onStartTanyaAI
Coordinator induk (createNavigationLinks / switch rute)
└── TanyaAICoordinator(greeting:shortcuts:)      ← hanya NavigationLink; nilai dari output induk, bukan binding
    └── TanyaAIDestination(greeting:shortcuts:)  ← @StateObject: UseCase dibuat, input ditulis, lalu view model
        └── Screen { TanyaAIScreen }   ← viewModel.host.makeView(onBack:)
```

```swift
// TanyaAIDestination.swift — autoclosure StateObject dijalankan sekali per halaman.
init(greeting: TanyaAIInitGreeting, shortcuts: [TanyaAIInitShortcut], onBack: @escaping () -> Void) {
    _viewModel = StateObject(wrappedValue: {
        let useCase = TanyaAIUseCase()
        useCase.input.greeting = greeting
        useCase.input.shortcuts = shortcuts
        return TanyaAIScreenViewModel(useCase: useCase)
    }())
    self.onBack = onBack
}

// TanyaAIScreenViewModel.swift — bridge dan host dibuat sekali, bukan setiap render.
@MainActor
private(set) lazy var bridge = TanyaAIBridge(
    transport: useCase,   // extension TanyaAIUseCase: TanyaAIChatTransport
    hostServices: useCase,   // extension TanyaAIUseCase: TanyaAIHostServices
    onSessionExpired: { [weak self] in self?.handleSessionExpired() },
    onConnectionFailed: { [weak self] error in self?.didReceiveError(error) }
)
@MainActor
private(set) lazy var host = TanyaAIHost(
    locale: Locale(identifier: Localize.currentLanguage()),
    welcome: useCase.repository.welcome,
    bridge: bridge
)

init(useCase: TanyaAIUseCase) {
    self.useCase = useCase
    super.init()
    useCase.loadWelcome()   // Input → Repository; sekali, sebelum `host` (lazy) dibaca di render pertama
}

// TanyaAIUseCase.swift — Input/Output non-optional dengan default; nil hanya di Repository.
func loadWelcome() {
    guard !input.greeting.title.isEmpty else {
        repository.welcome = nil   // nil = tanpa sambutan, bukan sambutan berisi teks kosong
        return
    }
    repository.welcome = WelcomeContent(
        greetings: input.greeting.greeting, shortcuts: input.shortcuts.map(\.shortcut)
    )
}
```

`TanyaAIHostServices` meminta satu properti per intent. Contoh ini mengambil adapter yang sudah disiapkan
oleh fitur Surat Referensi di host.

```swift
extension TanyaAIUseCase: TanyaAIHostServices {
    @MainActor var referenceLetter: ReferenceLetterService? { referenceLetterAdapter }
}
```

Kembalikan `nil` dari properti itu untuk menonaktifkan Surat Referensi. Host juga bisa memakai
objek khusus service intent, seperti [sandbox](../TanyaAISandboxApp/TanyaAI/SandboxReferenceLetterService.swift).
Untuk halaman yang tidak mendukung intent form, panggil `TanyaAIBridge(transport: useCase)`.

Input, Output, dan Repository memakai `struct`: `private(set) var repository` benar-benar mencegah view
model mengubah isinya, dan nilai yang dioper antarhalaman tidak saling berbagi referensi. Jangan memanggil
`loadWelcome()` di `.onAppear`/`.task`: `host` sudah dibuat dengan `welcome` nil pada render pertama.

Jangan membuat view model atau UseCase sebagai `let`/`@State` di coordinator: struct coordinator dibuat
ulang setiap render induk, sehingga nilai awalnya ikut dibuat ulang. Tanpa `flushData`: umur UseCase
terikat ke `@StateObject` destination. Kode lengkap yang bisa dijalankan ada di sandbox:
[TanyaAIEntryUseCase](../TanyaAISandboxApp/TanyaAI/TanyaAIEntryUseCase.swift) (inquiry induk),
[TanyaAIDestination](../TanyaAISandboxApp/TanyaAI/TanyaAIDestination.swift),
[TanyaAIUseCase](../TanyaAISandboxApp/TanyaAI/TanyaAIUseCase.swift),
[TanyaAIUseCase+Chat](../TanyaAISandboxApp/TanyaAI/TanyaAIUseCase+Chat.swift) (sama dengan kode Byon), dan
[TanyaAIChatService](../TanyaAISandboxApp/TanyaAI/TanyaAIChatService.swift) (tiruan service Alamofire).

Di coordinator induk, daftarkan `TanyaAICoordinator(selectionCoordinatorName: $destinationCoordinatorName, greeting:, shortcuts:)`
bersama link lain (pada host dengan registry lazy, tambahkan entri di dictionary link),
lalu buka dari callback UseCase induk setelah inquiry: `destinationCoordinatorName = TanyaAICoordinator.named`. Contoh lengkap:
[MainCoordinator](../TanyaAISandboxApp/Main/MainCoordinator.swift),
[DetailDestination](../TanyaAISandboxApp/Detail/DetailDestination.swift), dan folder
[TanyaAI sandbox](../TanyaAISandboxApp/TanyaAI).

Yang sengaja tidak dipakai: membungkus `NavigationView` main dengan `UINavigationController`
representable (safe area dan layout main rusak), serta router global yang memilih
halaman aktif (halaman di belakang yang dibangun ulang ikut melapor tampil sehingga
link salah halaman aktif). Akses "dari mana saja" sebaiknya menunggu navigasi revamp.

## 2. Aplikasi revamp dengan navigasi bersih

Package tidak bergantung pada pola di atas; coordinator dan base `Screen` milik host.
Untuk navigasi lain cukup ganti pemanggilnya:

- **SwiftUI `NavigationStack` (iOS 16+):** tambahkan route Tanya AI pada path, lalu
  `navigationDestination` menampilkan `host.makeView()`.
- **UIKit coordinator / `UINavigationController`:**
  `navigation.pushViewController(UIHostingController(rootView: host.makeView(onBack: pop)), animated: true)`.

`TanyaAIBridge` hidup selama halaman terbuka. Buat sekali di luar `body`. Host menyediakan transport per
endpoint gateway (body mentah) dan service intent melalui `hostServices:` bila dibutuhkan.
TanyaAI menyambung init → history → SSE selama halaman tampil, menyambung ulang, men-decode, dan
menggabungkan pesan. Lihat [chat-gateway](CHAT_GATEWAY.md).
`onSessionExpired` dipanggil sekali saat 401; `onConnectionFailed` sekali saat error `retryable:false`
menghentikan sambungan, saat kirim menemukan percakapan sudah hilang (404/410), atau saat respons init/history
tidak terbaca (`DecodingError`, bukan `TanyaAITransportError`); host menampilkan
error lalu menutup halaman. Gagal kirim lain ditangani TanyaAI. `locale` dan `colors` dibaca saat halaman dibuat.

## Halaman sambutan dan menunggu jawaban

Host memanggil inquiry init Tanya AI dan men-decode dengan model miliknya sendiri, lalu
memetakan ke `WelcomeContent`. Model welcome TanyaAI tidak `Decodable`; envelope
`response_code` dan field T&C tetap milik host. Contoh dari sandbox:

```swift
struct TanyaAIInitShortcut: Decodable {
    let title: String
    let description: String
    let iconUrl: String?
    let prompt: String

    var shortcut: WelcomeShortcut {
        WelcomeShortcut(
            title: title, description: description, iconURL: iconUrl.flatMap(URL.init(string:)), prompt: prompt
        )
    }
}
// TanyaAIUseCase.loadWelcome: WelcomeContent(greetings: greeting.greeting, shortcuts: shortcuts.map(\.shortcut))
```

| Bagian halaman | Sumber |
| --- | --- |
| Sapaan (`greetings.title`/`description`) | BE |
| Judul, deskripsi, ikon kartu (`shortcuts[].title`/`description`/`iconUrl`) | BE |
| Emblem, latar, judul "Mulai dari sini:", chevron | FE (package) |

Kontrak memakai key `description` (apib awal menulis `descripton`; BE diminta memperbaiki).
`iconURL` nil (kosong/tidak valid) menampilkan ikon fallback tanpa membatalkan kartu lain.

Ketuk kartu mengirim `prompt` lewat bridge, sama seperti chat dari composer.
Status menunggu jawaban **milik TanyaAI**: setelah host menerima chat, tombol kirim menjadi
stop dan bubble pertanyaan langsung tampil (draft boleh diketik untuk pertanyaan berikutnya); gagal
kirim menjadi bubble gagal di TanyaAI, bukan callback host. Kartu nonaktif dan chat berikutnya ditolak
tanpa diteruskan ke host sampai event `turn_end` datang. Stop memanggil `cancelTurn` transport
host (`POST /v1/chat/conversations/{id}/cancel`); host hanya meneruskan body mentah seperti endpoint lain.

Mulai 30 Oktober 2026 `TanyaAIChatTransport` mewajibkan `cancelTurn(conversationID:)`. Di Byon cukup
tambah satu fungsi di `TanyaAIUseCase+Chat` dengan pola continuation yang sama (contoh:
[TanyaAIUseCase+Chat](../TanyaAISandboxApp/TanyaAI/TanyaAIUseCase+Chat.swift)).

Mulai 10 November 2026 transport juga mewajibkan `leaveAgent(conversationID:)`
(`POST /v1/chat/conversations/{id}/leave-agent`, tanpa body) untuk tombol batal antrean live agent. Polanya
sama dengan `cancelTurn`: satu fungsi service callback dan satu fungsi continuation di `TanyaAIUseCase+Chat`.

Mulai 18 November 2026 transport juga mewajibkan `attachSuccessID(messageID:successID:)`
(`POST /v1/chat/messages/{message_id}/success-id`, body `{"success_id": "..."}`) untuk menandai pesan intent
selesai setelah transaksinya berhasil. Polanya sama dengan `leaveAgent`, dengan body JSON seperti `sendMessage`.

Mulai 18 November 2026 `TanyaAIHost` menerima `onSheetChange: (Bool) -> Void` (opsional). Tanya AI memanggilnya
`true` saat bottom sheet miliknya terbuka (pilihan lampiran) dan `false` saat tertutup; host menahan swipe-back
navigasinya selama `true`, sama seperti untuk sheet milik host. Di Byon: teruskan ke extension pop gesture global.

```swift
TanyaAIHost(locale: locale, colors: colors, welcome: welcome, bridge: bridge)
```

Ikon kartu dimuat `RemoteImage` DesignKit, pembungkus `KFImage` Kingfisher (dependency SPM
DesignKit, dikunci tepat 8.14.0, butuh Xcode 26). Cache memori + disk memakai `ImageCache.default`
Kingfisher (bawaan: disk kedaluwarsa 7 hari); host bisa mengatur batasnya di bootstrap bila
perlu. Status HTTP di luar 200..<400 dianggap gagal. Gambar di-downsample ke ukuran tampil ×
skala layar, dan unduhan dibatalkan saat view hilang.

Selama mengunduh kotak ikon menampilkan spinner (`ProgressView`); bila `iconUrl` kosong/tidak
valid atau unduhan gagal, tampil ikon default FE (lampu, TODO ganti ikon desain). Kartu tetap
tampil dan bisa diketuk. Kegagalan tidak di-cache, jadi halaman berikutnya mencoba lagi.
Cek di sandbox dengan `Scripts/run_sandbox.sh --broken-icons` (fallback) atau `--slow-icons` (loading).

## Bahasa dan appearance

Copy tersedia untuk `en`, `id`, dan `zh-Hans`, termasuk label kembali. Kode bahasa
Localize_Swift dipakai langsung sebagai `Locale`; bahasa lain jatuh ke English.
Daftarkan bahasa host pada konfigurasi localization target. Jika host belum
mendeklarasikan semua bahasa package, `CFBundleAllowMixedLocalizations = YES`
memungkinkan resource dependency ikut dipilih
([dokumentasi Apple](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleallowmixedlocalizations)).

Palette mengikuti `colors` pada `TanyaAIHost`; sebelum inquiry selesai memakai palette default.
Halaman Tanya AI memakai light appearance Figma (`.environment(\.colorScheme, .light)`
hanya pada subtree itu, tidak mengubah host). Pemetaan proposition ke palette tetap di host
karena aturan bisnis tidak masuk DesignKit.

## Isi folder `Bridging`

- `TanyaAIHost.swift`: konfigurasi (`locale`, `colors`, `welcome`, `bridge`) dan `makeView()`
  yang memasang bahasa dan palette ke halaman baru.
- `TanyaAIBridge.swift` (+ `+Connection`): objek yang dipegang host; pesan, status menunggu jawaban,
  dan siklus sambungan ke gateway.
- `TanyaAIChatTransport.swift` / `TanyaAITransportError.swift`: seam jaringan yang diimplementasikan host.
- `TanyaAIHostServices.swift`: kontrak service intent yang diimplementasikan host dan diberikan lewat `hostServices:`.

Overload `makeView { ContentView() }` menerima konten SwiftUI untuk area scroll; sandbox
memakainya pada mode `--header-demo`. Konten tidak perlu mempunyai ScrollView, header,
atau composer sendiri, dan dilepas setelah halaman di-pop.

Jalankan `Scripts/run_sandbox.sh --language id`. Buka Tanya AI dari beranda atau dari
halaman detail, kembali dengan tombol back atau swipe dari tepi kiri. `--offline`
membuat kiriman memunculkan blocker host di atas Tanya AI; tombol "Coba lagi"
menutupnya dan pertanyaannya tampil sebagai bubble gagal (`--reject-send` juga). Welcome sandbox dibaca dari
`Resources/Fixtures/TanyaAIInitDummy.json`; setelah chat/shortcut diterima, sandbox
menjawab lewat gateway tiruan setelah 1 detik (`--hold-reply` menahan jawaban).

## Link di jawaban bot

Jawaban bot berformat Markdown dirender `MarkdownContent` (DesignKit). Link yang diketuk tidak dibuka
TanyaAI (tanpa Safari fallback), tetapi tujuannya diteruskan ke host sebagai `String`:

```swift
host.makeView(onBack: pop, onOpenLink: { link in
    // web → webview host, deeplink → handler host, TanyaAILink.terms → halaman S&K host
})
```

Tanpa `onOpenLink`, tap link diabaikan.

## Syarat & ketentuan di sambutan

Kalimat di bawah kartu shortcut memakai copy lokal TanyaAI (`welcome.terms`) dan dirender `MarkdownContent`. Hanya
bagian "Syarat & Ketentuan" yang bisa diketuk, dan halamannya milik host. Tampil bila host mengisi
`WelcomeContent(..., isTermsVisible: true)`; default-nya tersembunyi, jadi cukup hapus argumen itu bila fitur belum
naik. Tap sampai ke `onOpenLink` sebagai `TanyaAILink.terms`.
