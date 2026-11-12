//
//  SandboxOptions.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 15/10/26.
//

import Foundation

/// Developer-only launch metadata. Gateway tiruan (`SandboxChatTransport`) menjawab tanpa backend.
struct SandboxOptions {
    static let fontFailure = "Font registration failed: "
    static let openIdentifier = "sandbox.open"
    static let detailOpenIdentifier = "sandbox.detail.open"
    static let detailTanyaAIIdentifier = "sandbox.detail.tanyaAI"
    static let offlineSimulateIdentifier = "sandbox.offline.simulate"
    static let offlineIdentifier = "sandbox.offline"
    static let offlineRetryIdentifier = "sandbox.offline.retry"
    static let logoutIdentifier = "sandbox.logout"
    static let loginIdentifier = "sandbox.login"
    static let demoStartIdentifier = "sandbox.demo.start"
    static let demoEndIdentifier = "sandbox.demo.end"
    static let formToggleIdentifier = "sandbox.formToggle"
    static let formToggleValueIdentifier = "sandbox.formToggle.value"
    static let formToggleChangeIdentifier = "sandbox.formToggle.change"
    static let formToggleEnabledIdentifier = "sandbox.formToggle.enabled"
    static let formToggleParentIdentifier = "sandbox.formToggle.parent"
    static let demoParagraphCount = 12
    static let sheetOpenIdentifier = "sandbox.sheet.open"
    static let sheetOptionIdentifier = "sandbox.sheet.option"
    /// `--sheet-demo`: jumlah baris contoh di dalam bottom sheet.
    static let sheetOptionCount = 4
    /// `--sheet-max`: batas tinggi sheet contoh, bagian dari tinggi layar.
    static let sheetMaxFraction: CGFloat = 0.6
    /// `--sheet-long`: jumlah baris contoh, lebih panjang dari layar.
    static let sheetLongOptionCount = 20
    /// Jeda pertanyaan nasabah muncul di stream setelah ack; selama ini bubble lokal yang tampil.
    static let echoDelay: TimeInterval = 0.6
    /// Jeda pesan bot yang datang sendiri setelah stream tersambung (`--late-message`).
    static let lateMessageDelay: TimeInterval = 3
    /// Jeda jawaban bot tiruan setelah pertanyaan muncul di stream.
    static let replyDelay: TimeInterval = 1
    /// `--live-agent`: jeda agen bergabung setelah antre, dan jeda agen menutup percakapan setelah menjawab.
    static let agentJoinDelay: TimeInterval = 3
    /// `--live-agent`: lama indikator agen mengetik sebelum pesannya datang.
    static let agentTypingDelay: TimeInterval = 1.5
    /// File yang tidak ada: unduhan ikon pasti gagal tanpa bergantung pada jaringan.
    static let brokenIconURL = URL(fileURLWithPath: "/sandbox/missing-icon.png")
    /// Alamat TEST-NET (RFC 5737) yang tidak pernah menjawab: ikon tertahan di state loading sampai timeout.
    static let slowIconURL = URL(string: "https://192.0.2.1/icon.png")
    private static let languageFlag = "--language"
    private static let rejectFlag = "--reject-send"
    private static let holdReplyFlag = "--hold-reply"
    private static let historyFlag = "--with-history"
    private static let longHistoryFlag = "--long-history"
    private static let lateMessageFlag = "--late-message"
    private static let lateQuestionFlag = "--late-question"
    private static let headerDemoFlag = "--header-demo"
    private static let sheetDemoFlag = "--sheet-demo"
    private static let sheetMaxFlag = "--sheet-max"
    private static let sheetLongFlag = "--sheet-long"
    private static let formToggleDemoFlag = "--form-toggle-demo"
    private static let offlineFlag = "--offline"
    private static let brokenIconsFlag = "--broken-icons"
    private static let slowIconsFlag = "--slow-icons"
    private static let hideTermsFlag = "--hide-terms"
    private static let liveAgentFlag = "--live-agent"

    /// Opsi dari argumen peluncuran proses ini.
    static var current: SandboxOptions {
        SandboxOptions(arguments: ProcessInfo.processInfo.arguments)
    }

    let locale: Locale?
    /// `--reject-send`: gateway menolak kirim (400), jadi bubble pertanyaan menjadi bubble gagal.
    let isRejectingSend: Bool
    /// `--hold-reply`: bot tidak pernah menjawab, jadi composer tetap di stop (untuk UI test stop).
    let isHoldingReply: Bool
    /// `--with-history`: gateway tiruan mengembalikan history fixture, jadi sambutan tidak tampil.
    let isShowingHistory: Bool
    /// `--long-history`: history lebih panjang dari satu layar, untuk menguji posisi scroll.
    let isShowingLongHistory: Bool
    /// `--late-message`: bot mengirim pesan sendiri tanpa ada pertanyaan, misalnya dari agen atau kanal lain.
    let isSendingLateMessage: Bool
    /// `--late-question`: pertanyaan nasabah datang dari kanal lain tanpa dikirim dari halaman ini.
    let isSendingLateQuestion: Bool
    /// `--hide-terms`: host tidak menampilkan syarat & ketentuan, seperti saat fiturnya belum naik.
    let isHidingTerms: Bool
    /// `--live-agent`: pertanyaan pertama diserahkan ke agen tiruan (antre → bergabung → menjawab → selesai).
    let isLiveAgent: Bool
    let isHeaderDemo: Bool
    /// `--sheet-demo`: area scroll berisi tombol yang membuka bottom sheet contoh di atas halaman Tanya AI.
    let isSheetDemo: Bool
    /// `--sheet-max` (bersama `--sheet-demo`): sheet contoh paling tinggi `sheetMaxFraction` layar.
    let isSheetMaxSet: Bool
    /// `--sheet-long` (bersama `--sheet-demo`): baris contoh lebih panjang dari layar, jadi isinya di-scroll.
    let isSheetLong: Bool
    let isFormToggleDemo: Bool
    let isOffline: Bool
    /// Pengganti semua `iconUrl` shortcut: `--broken-icons` (gagal, cek fallback) atau
    /// `--slow-icons` (tidak menjawab, cek loading). Nil = URL dari fixture.
    let iconOverrideURL: URL?

    init(arguments: [String]) {
        isRejectingSend = arguments.contains(Self.rejectFlag)
        isHoldingReply = arguments.contains(Self.holdReplyFlag)
        isShowingHistory = arguments.contains(Self.historyFlag)
        isShowingLongHistory = arguments.contains(Self.longHistoryFlag)
        isSendingLateMessage = arguments.contains(Self.lateMessageFlag)
        isSendingLateQuestion = arguments.contains(Self.lateQuestionFlag)
        isHidingTerms = arguments.contains(Self.hideTermsFlag)
        isLiveAgent = arguments.contains(Self.liveAgentFlag)
        isHeaderDemo = arguments.contains(Self.headerDemoFlag)
        isSheetDemo = arguments.contains(Self.sheetDemoFlag)
        isSheetMaxSet = arguments.contains(Self.sheetMaxFlag)
        isSheetLong = arguments.contains(Self.sheetLongFlag)
        isFormToggleDemo = arguments.contains(Self.formToggleDemoFlag)
        isOffline = arguments.contains(Self.offlineFlag)
        if arguments.contains(Self.brokenIconsFlag) {
            iconOverrideURL = Self.brokenIconURL
        } else if arguments.contains(Self.slowIconsFlag) {
            iconOverrideURL = Self.slowIconURL
        } else {
            iconOverrideURL = nil
        }
        if let position = arguments.firstIndex(of: Self.languageFlag),
            arguments.indices.contains(arguments.index(after: position))
        {
            locale = Locale(identifier: arguments[arguments.index(after: position)])
        } else {
            locale = nil
        }
    }
}
