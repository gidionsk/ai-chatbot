//
//  TanyaAIEntryUseCase.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 30/10/26.
//

import Foundation

/// Meniru bagian UseCase halaman induk Byon yang membuka Tanya AI: inquiry init, hasilnya ke `output`, lalu
/// `callback` meminta coordinator membuka halaman. Dipakai halaman Main dan Detail sandbox.
final class TanyaAIEntryUseCase {
    var callback = TanyaAIEntryCallback()
    private(set) var output = TanyaAIEntryOutput()

    /// Fixture rusak = output kembali ke default (kosong), halaman tetap dibuka tanpa sambutan.
    func inquire() {
        // TODO: Panggil inquiry init Tanya AI milik host setelah API tersedia; sandbox membaca fixture.
        let initData =
            SandboxFixtureFile.tanyaAIInitDummy.url
            .flatMap { try? Data(contentsOf: $0) }
            .flatMap { try? JSONDecoder().decode(TanyaAIInitResponse.self, from: $0) }?
            .data
        output.greeting = initData?.greetings ?? TanyaAIInitGreeting()
        output.shortcuts = initData?.shortcuts ?? []
        callback.onStartTanyaAI()
    }
}
