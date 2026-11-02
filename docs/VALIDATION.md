# Validasi starter

## Perbaikan review bridging lanjutan — 29 Oktober 2026

- Sesi habis final: `expireSession()` membatalkan task sambungan, jadi stream yang sedang terbuka ikut
  ditutup dan `run()` tidak lagi menimpa `expired` menjadi `connecting`/`live` (sebelumnya callback 401
  bisa terpanggil dua kali setelah reconnect).
- `ChatTurn` memegang `client_msg_id` pertanyaan yang ditunggu; ack atau penolakan pertanyaan lama
  (mis. sebelum percakapan berganti) diabaikan sehingga tidak mengunci/membuka pertanyaan baru.
- Error `retryable:false` saat pembukaan awal tidak lagi menyisakan spinner: `isLoadingHistory` hanya
  true selama masih menyambung, dan `onConnectionFailed` meneruskan error ke host sekali.
- Contoh transport Alamofire callback → async ditambahkan di `CHAT_GATEWAY.md`.
- Kirim 404/410 (percakapan hilang) memakai jalur gagal permanen yang sama dengan sambungan:
  stream ditutup, tidak menyambung ulang, `onConnectionFailed` tetap sekali. Gagal kirim lain menunggu
  snackbar TanyaAI (bukan callback host).

Test regresi: 401 saat kirim menutup stream tanpa reconnect, respons kirim terlambat dari percakapan
lama, 403 saat init menghentikan loading dan memanggil host sekali, ack/penolakan lama di `ChatTurn`.

## Perbaikan review bridging — 29 Oktober 2026

- Frame SSE selesai di baris `data:`; `turn_end` terakhir tidak lagi tertahan bila host membuang
  baris kosong (sebelumnya composer terkunci sampai event berikutnya).
- `ChatTurn`: hanya `turn_end` dengan seq setelah ack pertanyaan yang membuka kunci; `turn_end` sebelum
  ack dicocokkan saat ack tiba. `Last-Event-ID` = maks(seq pesan, `id` event terakhir selain typing).
- 401 saat kirim memanggil `onSessionExpired` sekali dan menghentikan sambungan, sama dengan jalur init.

Test regresi: parser tanpa baris kosong, replay `turn_end` lama, `turn_end` sebelum ack, 401 saat
kirim, cursor reconnect setelah `turn_end`, `id` typing tidak memajukan cursor.

## Menu "Percakapan baru" dihapus — 28 Oktober 2026

Ikon ⋮ dan menu "Percakapan baru" dihapus karena belum ada kebutuhan (alur BE: batas 1 percakapan
per CIF, close belum dipakai). `TanyaAIBridge(transport:onSessionExpired:)` tanpa `onNewConversation`;
copy `chat.more`/`chat.newConversation` dihapus dari tiga bahasa. Slot kanan header tetap kosong agar
judul di tengah; aset `moreMenu` disimpan. UI test sisi tombol kirim menunggu jawaban bot tiruan,
bukan percakapan baru.

## Sambutan vs history — 28 Oktober 2026

Loading di tengah halaman sampai init + history pertama selesai (`isLoadingHistory`); reconnect tidak
menampilkan loading. Sambutan hanya bila history kosong (`isWelcomeVisible`); pesan pertama dari stream
menggantikannya. Daftar pesan (bubble, chip tanggal per hari) menyusul di PR tampilan pesan. Sandbox
`--with-history` memuat fixture history. Test: status loading/sambutan, UI test history tanpa sambutan.

## Bridging chat-gateway — 28 Oktober 2026

Host mengimplementasikan `TanyaAIChatTransport` per endpoint (init, history, kirim, SSE) dan
mengembalikan body mentah; TanyaAI men-decode contract 1.0.1, menjalankan init → history → SSE
lewat `.task`, menyambung ulang dengan backoff 1–30 detik (atau `retry_after_ms`), dan menggabungkan
history baru berdasarkan `message_id` sampai bertemu pesan terakhir yang sudah ada. Stream dibuka
dengan `Last-Event-ID` = seq terbesar. 401 → `onSessionExpired`; `CLOSED` → history tanpa stream.
Pesan nasabah hanya tampil dari stream; `turn_end` membuka kirim. Daftar pesan menyusul di PR
tampilan pesan. Sandbox memakai gateway tiruan (`--hold-reply` menahan jawaban).

Test: parser SSE (dengan/tanpa baris kosong, komentar), decode event dari contoh swagger, merge,
backoff, urutan sambung/sambung ulang/kejar history/401/CLOSED/503/percakapan berganti, kirim
dari stream sampai `turn_end`; transport sandbox; UI test `turn_end` dari stream membuka kirim.

## Padding composer 16 di semua sisi — 28 Oktober 2026

Disamakan dengan Byon (sesuai Figma): `ComposerSection` memberi `spacingLarge` di semua sisi, bukan
`spacingMedium` atas-bawah. Ketahuan dari test Byon di iPhone 13 Pro: 2 × (17 − 8) = 18.

## Folder per bagian fitur Chat — 28 Oktober 2026

`Features/Chat/Models|Views/Sections` diganti folder per bagian: `ChatScreen.swift` di root fitur,
`Welcome/` (section + tiga model welcome), `Composer/`. Model tinggal dekat pemakainya. Hanya pindah
file (`git mv`), tanpa perubahan kode; SPM mengikuti folder, project sandbox tidak berubah.
`Bridging/` dan `Shared/` tetap. `Messages/`, `Flows/`, `ChatState/ChatAction` belum dibuat.

## Bayangan header saat digulir — 28 Oktober 2026

Header mendapat bayangan Figma `Shadow/Default` (x 0, y 2, blur 10, `#BEC3D0` 40%) lewat
`designShadow`, sama seperti kartu, dan gradient fade tetap ada. Fade dipasang sebagai background di
belakang surface; sebagai overlay, gradient putih menutupi bayangan. Muncul sebanding progres scroll;
saat diam header tetap transparan. Test piksel di window sandbox: fade di antara putih dan latar; di atas
latar putih, tepat di bawah header tetap ada bayangan saat digulir dan tidak ada saat diam.

## Divider composer dan penyesuaian dari Byon — 28 Oktober 2026

`ComposerSection` mendapat divider selebar layar di atas composer (`colorsOutlineNetral`,
`weightOutline` 1 di-scale). Disamakan dengan penyesuaian user di Byon: jarak isi `ActionCard`
`spacingMedium`, emblem welcome 60. Test layout: tinggi section = composer + padding vertikal +
tepat satu garis outline (toleransi 0,5, jadi hilangnya divider terdeteksi).

`ActionCard` kini tanpa garis tepi, hanya bayangan (Figma `default_recommendation`):
`.cardStyle(isOutlined: false)`; composer tetap ber-outline. Test piksel di window sandbox:
tepi kartu ber-outline berwarna, tepi kartu tanpa outline tetap putih.

## Header seukuran navigation bar host — 28 Oktober 2026

`ScreenHeader` disamakan dengan `NavigationBarView` host agar konsisten antar halaman: mulai dari
tepi atas layar, padding atas 50 (notch) / 28 tanpa scale (`CustomScreenInsets`), kiri-kanan 20,
bawah 15, ikon 24, judul Fira Sans Bold 16 dengan padding 32 di lapisan sendiri. Notch dibaca dari
safe area atas (> 20), bukan bawah seperti host, agar keyboard tidak menggeser header.
`ScreenContainer` membaca safe area sekali lewat GeometryReader di root. Nilai selain padding atas
memakai `.scaledToArtwork`; bila host ternyata tidak men-scale ikon/font/spacing, cukup ubah tokennya.

Dibuktikan oleh test: tinggi header sama dengan padding atas + ikon + padding bawah (notch dan
tanpa notch) pada lebar 320/375/430 dengan judul panjang; deteksi notch dari safe area atas
(0/20 tidak, 44/47/59 ya); konten container mulai tepat di bawah header + `spacingLarge`; header
transparan saat diam dan putih + fade saat digulir diukur dari tepi atas layar.

## Latar chat saat swipe back — 28 Oktober 2026

Di host Byon (simulator iOS 17.5), swipe back setengah dari Tanya AI menampilkan halaman putih:
latar dan isi scroll hilang, header dan composer tetap tampil. Bisect di host: konten diganti
`Color.red` mulus; welcome dihapus masih putih; latar dihapus mulus. Penyebab: latar
`scaledToFill` + frame tak hingga + `clipped`. Latar kini `scaledToFit` menempel di atas
(artwork satu layar 375×812, jadi tampilan iPhone praktis sama); diverifikasi user di Byon iOS 17.5.
Sandbox (iOS 26) tidak mereproduksi bug ini, termasuk saat bridge dibuat ulang setiap render.
Mac ini belum punya runtime iOS 17, jadi belum ada UI test otomatis untuk kasus ini.

## Bridge host dan struktur TanyaAI — 28 Oktober 2026

Model welcome TanyaAI tidak lagi `Decodable`; host men-decode inquiry init (sandbox: DTO
`TanyaAIInit*`) lalu memetakan ke `WelcomeContent`. `TanyaAIBridge` dipegang host dan memegang
`onSend`/`onNewConversation`; status menunggu jawaban pindah dari host ke bridge. Event SSE dan
event penghenti loading menyusul bersama contract. Folder TanyaAI: `Bridging/`,
`Features/Chat/Models|Views(/Sections)`, `Shared/Keys|Extensions`, `Resources/`.

Dibuktikan oleh test: bridge menunggu setelah chat diterima, menolak chat berikutnya tanpa
memanggil host, berhenti menunggu dan memanggil host saat percakapan baru, menu nonaktif
tanpa handler; bridge tidak menahan view model host; decode init di sandbox (urutan, `iconUrl`
kosong/null/hilang, typo `descripton` ditolak); `FontFace.swiftUIFont` sama ukurannya dengan
jalur `UIFont`. UI test welcome (loading sampai percakapan baru) tetap lulus.

## Halaman sambutan dari BE — 27 Oktober 2026

Welcome mengikuti apib inquiry init: host men-decode objek `data` ke `WelcomeContent`
(sapaan + shortcut, urutan BE). Kartu memakai `ActionCard` DesignKit dengan ikon dari
`iconUrl` lewat `RemoteImage`; emblem, latar, judul daftar dan chevron dari FE. Ketuk kartu
mengirim `prompt` lewat `onSend`; selama `isAwaitingReply` tombol kirim menjadi
`LoadingDots` dan kartu nonaktif. Ukuran/tipografi masih estimasi screenshot (TODO).

Dibuktikan oleh test: decode contoh BE (field T&C diabaikan), `iconUrl` kosong/null/tidak
ada tetap memberi kartu, key `descripton` ditolak (BE diminta memperbaiki); setiap `ChatImage`
termuat dari bundle package; view model sandbox membaca fixture, menunggu jawaban setelah
chat diterima sampai percakapan baru, dan tidak menunggu bila ditolak/offline. UI test:
sapaan dan tiga kartu berurutan (id), ketuk kartu mengubah label kirim menjadi "Waiting for
reply" dan menonaktifkan kirim serta kartu walau draft diisi, lalu percakapan baru
memulihkannya. Tes ketuk tepi tombol kirim kini memulai percakapan baru di antara kiriman.

Ikon dari URL: `RemoteImage` kini pembungkus `KFImage` Kingfisher 8.14 (keputusan user:
pakai library teruji, menggantikan loader buatan sendiri). Cache memori + disk, downsample
(`DownsamplingImageProcessor`), validasi status HTTP (200..<400) dan batal saat view hilang
ditangani Kingfisher. Test: unduhan gagal menampilkan placeholder lalu fallback; URL nil
langsung fallback. UI test `--slow-icons`: spinner tampil di kotak ikon dan kartu sudah bisa
diketuk; `--broken-icons`: ikon fallback tampil dan kartu tetap bisa diketuk.

Line-height teks welcome/kartu sengaja mengikuti bawaan font (keputusan user): tidak ada
kompensasi `lineSpacing` di luar composer.

## Tanpa R.swift — 27 Oktober 2026

CI host (fastlane gym, Xcode 26) gagal di `Validate plug-in "RswiftGenerate…Resources"`:
build tool plugin wajib di-trust per mesin dan runner non-interaktif tidak bisa. R.swift
dilepas dari DesignKit, TanyaAI dan sandbox. Copy memakai enum key (`ChatCopy`,
`SandboxCopy`) dan `String(key:bundle:locale:)`; ikon memakai `DesignIcon`
(`Foundations/Iconography`). Pengganti pengecekan compile R.swift: tes per bahasa bahwa
key enum sama persis dengan isi `Localizable.strings`, serta tes setiap `DesignIcon`
termuat dan setiap imageset punya case. Lookup copy sengaja tanpa cache; biayanya setara
Localize_Swift di host dan R.swift sebelumnya.

## Unit test ke Swift Testing — 26 Oktober 2026

Seluruh unit test (`DesignKitTests`, `TanyaAITests`, `TanyaAISandboxTests`) pindah dari
XCTest ke Swift Testing tanpa mengubah perilaku yang diuji. `swift-tools-version` tetap
5.7; Swift Testing ikut toolchain Xcode 16 ke atas. UI test tetap XCTest. Penantian async
memakai `waitUntil` berbasis `Task.sleep`; suite sandbox yang memakai window berada di
bawah `HostWindowTests` yang `.serialized`, dan `TanyaAIHostTests` juga `.serialized`.

Hasil: DesignKit 17 tes (warna hex tidak valid tanpa fallback kini tes sendiri), TanyaAI
4, sandbox unit 8, ditambah UI test XCTest; lint 0 pelanggaran.

## Style permukaan dan header — 22 Oktober 2026

DesignKit menambah `.cardStyle()` (isi, radius, garis tepi, bayangan) dan
`.designShadow()`. `MessageComposer` memakai `.cardStyle()`, jadi tampilannya tidak
berubah; radius pindah dari `CustomSizes.Composer` ke `CustomSizes.Card`.
`ScreenHeader` kini transparan saat diam dan putih saat digulir, dengan gradient
setinggi `spacingLarge` di bawahnya; material blur dan separator dihapus.

Dibuktikan oleh test: kedua modifier tidak mengubah ukuran layout; di app host,
warna piksel menunjukkan header tembus ke latar saat diam, putih saat digulir,
gradient di antara keduanya, dan latar kembali terlihat di bawah gradient.

## Tanya AI sebagai view SwiftUI — 22 Oktober 2026

`TanyaAIHost.makeViewController()` diganti `makeView()`: host SwiftUI tidak lagi
membungkus halaman ke `UIHostingController` lalu ke representable. Tampilan terang
dibatasi lewat `.environment(\.colorScheme, .light)`; tanpa `onBack`, tombol kembali
memakai `dismiss` SwiftUI. Sandbox mengikuti pola host: coordinator hanya berisi
`NavigationLink`, view model dipegang `@StateObject` di view tujuan
(`TanyaAIDestination`, `DetailDestination`), dan main dibuang saat logout.
`TanyaAIRouter` dan `TanyaAIPage` dihapus.

Dibuktikan oleh test: halaman full screen dan composer ada di halaman yang di-push;
render ulang halaman induk tidak mengganti halaman yang terbuka; UI test keyboard,
inset visual, swipe-back, buka dari detail, blocker offline, dan logout/login lulus.

## Host tiruan SwiftUI — 20 Oktober 2026

Sandbox kini meniru host: `RootScreen` (prelogin + main tetap hidup), base `Screen`,
`ScreenContentViewModel`, coordinator dengan tag, extension pop-gesture global, dan
`TanyaAIRouter` + satu link di base `Screen`. `RevampNavigationController`,
`SandboxRouter`, `SandboxHostView` dan `RevampNavigationTests` dihapus.

Dibuktikan oleh test:
- Tanya AI terbuka full screen dari beranda dan dari halaman detail tanpa didaftarkan
  per coordinator; ketukan ganda diabaikan; back kembali ke halaman asal;
- SwiftUI mem-pop beberapa halaman sekaligus saat Tanya AI terbuka: router ikut
  bersih dan Tanya AI bisa dibuka lagi;
- logout menutup Tanya AI; swipe-back hanya aktif bila ada halaman untuk kembali;
- UI test: `--offline` memunculkan blocker host di atas Tanya AI dan draft tetap ada
  setelah "Coba lagi"; logout lalu login kembali ke main.

Belum diuji pada perangkat iOS 15–17; simulator yang tersedia iOS 26.5.

## Host lebih sederhana — 20 Oktober 2026

`TanyaAIHostEnvironment` dan `HostEnvironmentReader` dihapus. `TanyaAIHost` menjadi
struct konfigurasi; `locale` dan `colors` dipasang ke environment saat halaman dibuat.
Live update dihapus karena bahasa diganti dari Settings dan theme dipilih saat inquiry
proposition, keduanya sebelum Tanya AI dibuka. Init `ChatScreen` tanpa konten yang
tidak dipakai juga dihapus.

Dibuktikan oleh test: `locale`/`colors` diterapkan pada halaman baru, perubahan
berlaku pada halaman berikutnya, dan halaman yang sudah terbuka tidak berubah.
Integrasi host SwiftUI (coordinator + base screen) diuji pada replika: halaman full
screen, blocker base screen tampil di atasnya, view model stabil saat parent render
ulang, dan logout menutup Tanya AI.

## Jalur navigasi host — 18 Oktober 2026

Tanya AI tidak lagi dipresentasikan sebagai modal dengan transisi custom. Host
mem-push `tanyaAI.makeViewController()` ke `RevampNavigationController` (contoh di
sandbox, yang kini memakai AppDelegate + SceneDelegate seperti host). Dihapus dari
package: anchor `.tanyaAIHost`, present/dismiss, transisi dan swipe custom, logika
menyembunyikan host, serta `CustomMotion` yang tidak lagi dipakai.

Dibuktikan oleh test:
- swipe-back native hanya aktif saat ada halaman untuk kembali; UI test dengan gesture
  jari: geser pendek batal, geser panjang kembali ke host;
- blocker UIKit (no internet) dan sheet SwiftUI dari main (session expired) tampil di
  atas Tanya AI;
- mengganti root window ke prelogin melepas Tanya AI; router tidak mem-push dua kali;
- halaman dan konten dilepas setelah pop; `locale`/`colors` diterapkan dan live.

UI test header kini menyasar scroll view konten secara eksplisit, karena
`scrollViews.firstMatch` bisa menunjuk bar saran keyboard.

## Tanpa literal di kode package — 18 Oktober 2026

`forwardDirection = 1` dan batas `1` pada swipe-back dihapus; arah dihitung dari lebar
layar dan arah layout. Transisi menjadi satu file tanpa pengecualian script, jadi
literal baru di sana akan ditolak. Parser hex memakai `HexFormat` dengan konstanta
format bernama dan urutan kanal `Channel`, tanpa mask/shift manual.

## Tanpa forcing — 18 Oktober 2026

`BoundedTextView` tidak lagi meng-override `text: String!`; `GrowingTextInput`
memanggil `remeasure()` setelah teks/style berubah. Bacaan `UITextView.text` memakai
`?? String()`. UI test memakai `let application = XCUIApplication()`. SwiftLint
mengaktifkan `force_unwrapping` dan `implicitly_unwrapped_optional` (ditambah
`force_cast`/`force_try` bawaan); keempatnya dibuktikan menolak pelanggaran sengaja.

## Struktur untuk skala — 18 Oktober 2026

Identifier UI test dikelompokkan per komponen; transisi akhirnya disatukan dalam satu file
`Host/TanyaAIPushTransition.swift` (164 baris, sebelumnya 271 baris di 3 file); fixture window test Sandbox di file sendiri; alias
`CustomColors.transparent` dihapus. Tipografi tetap memakai token `FigmaSize`
per role secara langsung.

## Pemisahan token custom — 18 Oktober 2026

`CustomSizes` dipecah menjadi `CustomSizes` (dimensi, selalu di-scale),
`CustomTextLines`, `CustomMotion`, `ArtworkScale`, dan `LayoutTolerance`. Perubahan
murni penggantian nama; nilai tidak berubah. `check_design_system.py` sekarang
menolak `CustomSizes` tanpa `.scaledToArtwork` serta baris/motion/toleransi yang
di-scale; kedua aturan dibuktikan dengan pelanggaran sengaja. `Scripts/verify.sh`
lulus: lint 0 pelanggaran, seluruh test package, hosted dan UI lulus.

## Kesiapan revamp — 17 Oktober 2026

Perubahan: host lifecycle (completion dismiss tidak hilang, `present()` → Bool,
fitur tertutup saat main diganti prelogin), swipe-back interaktif, theme lewat
environment, draft di `ComposerSection`, measurement editor hanya saat teks/lebar
berubah, nilai awal bawaan tipe, R.swift `from: "7.8.0"`.

`Scripts/verify.sh` lulus pada iPhone 17 Pro Simulator (Xcode 26), minimum iOS 15.
Saat dijalankan tanpa trust plugin R.swift, `xcodebuild` memerlukan
`-skipPackagePluginValidation`; script repo tidak diubah.

| Suite | Hasil |
| --- | --- |
| DesignKit: + theme environment (3), editor remeasure saat lebar berubah (1) | 15 lulus |
| TanyaAI: + animator saat host tertutup/swipe batal, interaksi swipe (3) | 10 lulus |
| Hosted: + present Bool, completion ganda, swipe batal + deeplink, main→prelogin, root UIKit diganti, `locale`/`colors` dari host awal dan saat terbuka | 15 lulus |
| UI: tiga bahasa, padding desain, keyboard, empat baris, header/menu | 11 lulus |

Total **51 tes lulus**. Belum ada pengukuran Instruments/FPS; swipe-back diuji
secara programatik melalui `UIPercentDrivenInteractiveTransition`, belum dengan
gesture jari pada device.

## Pembagian view dan ukuran desain — 17 Oktober 2026

Deklarasi view utama menyimpan input/state, initializer, `body`, dan bagian visual.
Setup, perhitungan dan validasi dipisah ke `private extension` Helpers pada file
yang sama; handler dipisah ke extension Actions. Stored properties tetap pada
deklarasi utama. Pemisahan source tidak menambah object, state, atau cache runtime.

Ukuran interaksi dan tebal stroke sekarang mengikuti nilai desain melalui
`.scaledToArtwork` langsung. Tidak ada minimum tap/stroke atau frame interaksi
tambahan dari SDK. Padding composer memakai `spacingLarge` di semua sisi tanpa
kompensasi inset. Font input tetap 14, maksimum empat baris, satu baris sejajar
tengah, dan tombol bertahan di bawah ketika editor membesar.

Verifikasi terbaru menggunakan `xcodebuild test` pada iPhone SE, iOS 26.5:

| Suite | Hasil |
| --- | --- |
| DesignKit: font, asset, sizing, editor, header, paste panjang/release | 11 lulus |
| TanyaAI: localization, anchor, animator | 7 lulus |
| Hosted: present/dismiss, release, caret, container, scroll boundary | 8 lulus |
| UI: tiga bahasa, padding desain, keyboard, empat baris, header/menu | 11 lulus |

Total **37 tes lulus**, tanpa kegagalan atau skip. Build dan lint lulus. Screenshot
native input kosong, empat baris dengan keyboard, serta header setelah scroll
diekspor dari hasil test dan diperiksa. Test UI sekarang memeriksa ukuran desain
langsung, tanpa mengasumsikan minimum tap SDK. Tidak ada pengukuran FPS/Instruments.

## Perubahan R.swift — 17 Oktober 2026

| Pemeriksaan perubahan terbaru | Hasil |
| --- | --- |
| SwiftLint, formatter, batas file/method, token/copy guard | Lulus, tanpa pelanggaran |
| Manifest DesignKit/TanyaAI dan referensi plugin/runtime pada project | Lulus |
| Generator R.swift untuk package dan sandbox project | Lulus |
| Kompilasi modul DesignKit/TanyaAI terhadap SDK iOS Simulator, minimum iOS 15 | Lulus melalui swiftc |
| Pemeriksaan tipe test kedua package dan sandbox dengan accessor generated | Lulus |
| Resource localization fitur dan sandbox | 20 assertion lulus pada macOS |
| Kompilasi tiga PDF imageset menjadi Assets.car | Lulus melalui actool |
| Full xcodebuild generic iOS Simulator dengan plugin/resource bundle | Lulus setelah cleanup mapping lama |
| Unit package pada simulator iOS 26.5 | 18 tes lulus: DesignKit 11, TanyaAI 7 |
| Hosted test dan UI automation terbaru | 19 tes lulus: hosted 8, UI 11 |
| Diff token generated dan tujuh font | Tidak berubah |

Pemeriksaan localization menjalankan source `String+Resource.swift` dan accessor
R.swift asli terhadap bundle berisi ketiga `.lproj`. Mencakup English, Indonesia,
`zh-Hans`, pemilihan Chinese untuk `zh_CN`, dan fallback English untuk `fr_FR`.

Full `xcodebuild` setelah cleanup berhasil menjalankan plugin R.swift pada target
package dan sandbox, mengompilasi xcassets serta membangun resource bundle asli.
Pemeriksaan swiftc sebelumnya hanya memakai accessor `Bundle.module` sementara
untuk pemeriksaan kompilasi. `AssetTests` kini lulus saat memuat ketiga ikon dari
bundle package yang sebenarnya pada simulator.

Percobaan awal sempat terhalang lingkungan dan ketidakcocokan CoreSimulator.
Setelah versi simulator sesuai, ketiga suite dijalankan ulang melalui
`xcodebuild test`: total 37 tes lulus seperti tercatat di atas. Screenshot dan
35 tes pada bagian berikut tetap **baseline 16 Oktober**; screenshot baseline
tidak menggambarkan seluruh perubahan asset dan aturan ukuran terbaru.

Audit terbaru juga menambahkan uji paste 19.000 karakter campuran Chinese/English.
Editor mempertahankan batas empat baris, scrolling aktif, menyusut setelah
dibersihkan, dan instance editor dilepas setelah pemiliknya berakhir. Ini menguji
tinggi dan lifecycle editor; bukan pengukuran FPS/latensi paste atau bukti bahwa
semua jalur aplikasi bebas memory leak.

App sandbox berhasil dipasang dan dijalankan pada simulator iPhone SE iOS 26.5.
Tes UI membuka fitur lewat tombol host, berinteraksi dengan header/composer,
lalu menutup dan membuka fitur kembali.

## Audit readability dan biaya runtime

View utama memiliki body ringkas dengan helper/aksi pada extension terpisah.
API SwiftUI standar, input immutable, state lokal, dan callback eksplisit membuat alur mudah
ditelusuri. Bagian lebih kompleks terisolasi pada editor UIKit dan animator
presentasi, dengan komentar alasan perilaku khusus. Pola view, callback dan
penempatan komponen ada pada [panduan view](VIEW_TEMPLATE.md).

- `ScreenContainer`, `ScreenHeader`, `MessageComposer`, `GrowingTextInput`, sizing,
  font dan scroll boundary sudah berada di DesignKit, tanpa ketergantungan fitur.
- Callback sederhana tetap memakai tipe closure langsung. Typealias hanya
  diperlukan ketika memberi nama kontrak domain yang kompleks/berulang.
- R.swift menghasilkan source saat build. Akses runtime tetap lookup resource.
  Microbenchmark macOS untuk enam label bersama mencatat sekitar 0,11 ms per
  kelompok pada 30.000 iterasi. Ini bukan benchmark rendering pada iPhone.
- Scroll menyimpan status Boolean dan melapor saat boundary berubah. Geometri
  tetap dibaca saat layout; tidak ada klaim bahwa cost scroll menjadi nol.
- Font didaftarkan sekali; editor menginvalidasi tinggi hanya ketika ukuran
  berubah. Measurement teks tetap dipengaruhi panjang input meskipun tinggi
  editor dibatasi empat baris.
- Audit reference menemukan weak anchor/presented controller, weak callback back,
  serta delegate yang diputus saat dismantle. Callback dari host tetap perlu
  capture ownership yang sesuai agar caller tidak membuat siklus sendiri.

Struktur ini layak sebagai baseline migrasi bertahap. Belum ada profil Instruments
Leaks/Allocations atau frame time pada device; jangan
mengartikan hasil unit test sebagai jaminan performa/bebas leak pada semua flow.
Pengukuran body/dependency mengikuti [panduan performa Apple](https://developer.apple.com/documentation/xcode/understanding-and-improving-swiftui-performance).

Tiga file mapping lama (`ChatCopy`, `SandboxCopy`, `SystemSymbol`) dan konstanta
rotasi ikon yang tidak dipakai sudah dihapus setelah persetujuan pengguna.

Ikon send/back/more kini berupa PDF vector dummy dalam xcassets, diakses lewat
R.swift. TODO penggantian export Figma ada pada README asset. Layout/padding,
ukuran font tetap 14, dan batas empat baris tidak diubah.

## Baseline — 16 Oktober 2026

`Scripts/verify.sh` lulus pada simulator iPhone SE 375×667, iOS 26.5.
Tiga tes UI header juga lulus saat dijalankan terpisah pada iPhone 17 Pro,
iOS 26.5 (402×874 point).

| Pemeriksaan | Hasil |
| --- | --- |
| DesignKit: registrasi tujuh font/glyph, hex, sizing, editor, header dan layout | 9 tes lulus |
| TanyaAI: locale, optional anchor/identity, pergantian host, animator | 7 tes lulus |
| Hosted unit: presentasi, lifecycle, caret, reusable container dan isolasi boundary | 8 tes lulus |
| UI: composer/caret, tiga bahasa, header, scroll, menu, keyboard dan tutup/buka | 11 tes lulus |
| Build generic iOS Simulator, deployment minimum iOS 15 | Lulus |
| SwiftLint/formatter, batas file/method, token/copy guard | Lulus |
| Link dokumentasi dan generated token diff | Lulus; generated token tidak berubah |

Total **35 tes unik**. Unit layout mencakup lebar 320/375/430 dengan normal dan
accessibility XXXL (font composer tetap). Sizing diuji sampai 1024 point tanpa cap.
Ini bukan pengujian UI iPad, runtime iOS 15/device atau pengukuran rendered FPS.

Pengujian presentasi memakai `TanyaAISandboxTests` dengan sandbox app sebagai
test host dan UIWindowScene aktif. SwiftPM unit tests hanya menangani layout
anchor/identity dan algoritma animator; logic test tanpa app tidak mempunyai
scene aktif untuk menyelesaikan transisi fullscreen. Target hosted test memakai
minimum iOS 17 sesuai toolchain test; minimum app/package tetap iOS 15.

## Pemeriksaan visual

Empat belas screenshot native berikut diekspor dari hasil UI test dan diperiksa.
Gambar tidak diedit atau dibuat dengan generator gambar.

- [English](../Artifacts/Screenshots/starter-en.png)
- [Bahasa Indonesia](../Artifacts/Screenshots/starter-id.png)
- [简体中文](../Artifacts/Screenshots/starter-zh-Hans.png)
- [Satu baris dan keyboard](../Artifacts/Screenshots/starter-one-line-keyboard.png)
- [Empat baris dan keyboard](../Artifacts/Screenshots/starter-four-lines-keyboard.png)
- [Pengaturan accessibility XXXL, font composer tetap](../Artifacts/Screenshots/starter-accessibility-zh-Hans.png)
- [Kosong dan fokus](../Artifacts/Screenshots/starter-empty-focused.png)
- [Caret setelah mengetik](../Artifacts/Screenshots/starter-caret-one-line.png)
- [Kosong setelah dihapus](../Artifacts/Screenshots/starter-empty-after-clearing.png)
- [Header dan awal konten dummy](../Artifacts/Screenshots/header-demo-top.png)
- [Header setelah scroll](../Artifacts/Screenshots/header-demo-scrolled.png)
- [Kembali ke atas](../Artifacts/Screenshots/header-demo-returned.png)
- [Awal konten di iPhone 17 Pro](../Artifacts/Screenshots/header-demo-top-large.png)
- [Setelah scroll di iPhone 17 Pro](../Artifacts/Screenshots/header-demo-scrolled-large.png)

Action tetap terlihat dan berada di atas keyboard. Teks panjang scroll di dalam
editor setelah empat baris. UI test memeriksa pusat field/tombol sejajar saat
kosong/satu baris dan posisi tombol tetap saat teks bertambah menjadi empat
baris atau lebih, pada pengaturan teks normal dan accessibility XXXL. Setelah kirim,
input menyusut dan kembali sejajar tengah. Ketujuh font Fira Sans/Open Sans terdaftar dengan
PostScript name yang dibaca dari file aslinya. Registrasi dua kali diuji aman;
Chinese memakai fallback glyph native pada setiap face, diuji tanpa glyph 0.
SF Symbol send/back/more masih dummy TODO. Verifikasi font brand final tetap mengikuti aset
resmi yang nanti diberikan, termasuk keputusan font Chinese brand.

Composer dan placeholder memakai token 14 dengan leading role 21, hanya mengikuti
artwork scaling; Dynamic Type tidak mengubah font/leading composer. UI test
membandingkan ukuran field kosong, satu baris, empat baris dan composer pada
pengaturan normal dengan accessibility XXXL: semuanya tetap sama.
Pada artwork 375, tes UI baseline memeriksa jarak 16 antara border dan lingkaran
tombol kanan/bawah, field kiri, serta field atas ketika multiline. Baseline saat
itu mempunyai area interaksi tambahan; aturan tersebut sudah diganti dengan
ukuran desain langsung pada 17 Oktober. Screenshot baseline tidak menjadi acuan
area interaksi implementasi terbaru.

Regresi caret direproduksi pada ketujuh font: koreksi yang hanya memusatkan caret
kosong ke bounds membuat posisinya berbeda 0,25–0,5 point dari caret saat mengetik.
Tes hosted gagal sebelum perbaikan dan lulus setelah geometri native dipakai pada
semua state. Rect caret di awal dokumen dibandingkan saat kosong, setelah mengetik
dan setelah menghapus draft: semuanya tetap sama. Hint dan input memakai font
yang sama; ZStack `.leading` memusatkan hint secara vertikal pada field.

Screenshot sekarang diambil setelah membuka feature melalui `.tanyaAIHost(host)`
dan `host.present()`. Header SwiftUI menyediakan judul, kembali dan menu titik tiga.
UI test memastikan tombol kembali
menutup feature dan presentasi berikutnya memulai draft kosong.

## Header dan scroll

Tes UI memeriksa judul di tengah, frame action back/more, jarak awal
konten dari header, perubahan boundary ketika scroll, mencapai akhir, lalu
kembali ke state awal. Header dan composer tetap pada posisi yang sama. Header
tetap stabil dengan keyboard dan input empat baris, termasuk pada pengaturan
teks accessibility XXXL. Menu diterjemahkan dalam tiga bahasa; tanpa handler sesi,
item “Percakapan baru” disabled. Pembuatan sesi/welcome belum diimplementasikan.

Screenshot memperlihatkan separator dan surface material setelah scroll; judul
tetap tajam. Unit layout menguji judul sangat panjang pada lebar 320/375/430,
dengan dan tanpa trailing action. Fallback Reduce Transparency memakai surface
opaque; pengaturan sistem ini belum diuji melalui otomasi UI.

Tes hosted memastikan injected content dilepas setelah dismiss walaupun host
masih dimiliki caller. Tes lifecycle existing juga lulus. Ini menguji ownership
jalur present/dismiss yang tersedia, bukan audit Instruments seluruh aplikasi.
Tes presentasi juga memastikan screen fitur tidak mempunyai UINavigationController
di dalam hierarchy-nya, sementara navigation stack host tetap utuh.

## Reuse dan pembatasan update scroll

`ChatScreen` menggunakan `ScreenContainer` DesignKit. Container menyimpan satu
progres scroll 0...1, memakai ID UUID lokal melalui `@State`, dan memasang header/scroll/footer otomatis.
Modifier `.onScrollProgressChange` juga diuji terpisah dari fitur chat pada dua
ScrollView bertingkat: menggeser inner tidak mengubah progres outer, dan sebaliknya.
Offset 0,2 point di bawah toleransi tetap 0. Setengah `distance` = 0,5; empat perpindahan
offset setelah `distance` hanya menghasilkan satu laporan 1 (tidak ada render ulang lagi);
kembali ke atas melaporkan 0. Nilai awal dikirim sekali saat muncul.

Tes container dengan beberapa child ViewBuilder memastikan inset header dan
margin diterapkan satu kali pada keseluruhan konten, bukan berulang per child.
Callback count ini membatasi update state; GeometryReader tetap mengevaluasi
geometri saat layout scroll berubah. Tidak ada klaim hasil FPS atau profiling
Instruments berdasarkan tes callback tersebut.

## Transisi header progresif — 30 Oktober 2026

Keputusan user: header tidak lagi berganti mendadak dari transparan ke solid. `ScreenHeader` menerima
`scrollProgress` 0...1; surface putih, bayangan, dan gradient memudar sebanding nilai itu. Jarak transisi
= tinggi header (`ScreenHeader.height(isNotched:)`), jadi tidak ada token baru; posisi teratas (termasuk
bounce) selalu 0 = transparan penuh. Identifier `header.scrolled` tetap berarti "tidak di posisi teratas".
Test piksel: progres 0,25 lebih dekat ke latar daripada 0,5, dan 0,5 berada di antara latar dan putih.
