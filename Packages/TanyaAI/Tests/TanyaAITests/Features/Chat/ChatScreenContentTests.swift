//
//  ChatScreenContentTests.swift
//  TanyaAITests
//
//  Created by Wendra on 6/11/26.
//

import SwiftUI
import Testing
import UIKit

@testable import TanyaAI

/// Konten sisipan host berada di dalam sel table, jadi perubahan state host harus sampai ke sel yang sedang tampil.
@MainActor
@Suite(.serialized)
struct ChatScreenContentTests {
    @Test
    func injectedContentFollowsTheStateOfTheHost() async {
        let model = ContentModel()
        let probe = ContentProbe()
        let window = makeWindow(model: model, probe: probe)
        defer { window.isHidden = true }
        await waitUntil { probe.label == "Before" }
        model.label = "After"
        await waitUntil { probe.label == "After" }
    }

    /// Tinggi baris ikut berubah, jadi konten yang tumbuh tidak terpotong oleh tinggi lama.
    @Test
    func injectedContentResizesItsRow() async {
        let model = ContentModel()
        let probe = ContentProbe()
        let window = makeWindow(model: model, probe: probe)
        defer { window.isHidden = true }
        await waitUntil { probe.frameHeight == ContentModel.shortHeight }
        model.height = ContentModel.tallHeight
        await waitUntil { probe.frameHeight == ContentModel.tallHeight }
    }

    /// Menyegarkan konten terjadi di dalam update halaman, jadi tidak boleh memicu update berikutnya tanpa henti.
    @Test
    func anIdlePageStopsRebuildingTheContent() async throws {
        let model = ContentModel()
        let probe = ContentProbe()
        let window = makeWindow(model: model, probe: probe)
        defer { window.isHidden = true }
        await waitUntil { probe.label == "Before" }
        try await Task.sleep(nanoseconds: 300_000_000)
        let settledRenders = probe.renders
        try await Task.sleep(nanoseconds: 300_000_000)
        #expect(probe.renders == settledRenders)
    }

    private func makeWindow(model: ContentModel, probe: ContentProbe) -> UIWindow {
        let host = TanyaAIHost(bridge: TanyaAIBridge(transport: FakeChatTransport()))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        window.rootViewController = UIHostingController(rootView: ContentPage(host: host, model: model, probe: probe))
        window.makeKeyAndVisible()
        window.rootViewController?.view.layoutIfNeeded()
        return window
    }
}

@MainActor
private final class ContentModel: ObservableObject {
    static let shortHeight: CGFloat = 40
    static let tallHeight: CGFloat = 160
    @Published var label = "Before"
    @Published var height = ContentModel.shortHeight
}

private final class ContentProbe {
    var label: String?
    var frameHeight: CGFloat?
    var renders = 0
}

private struct ContentPage: View {
    let host: TanyaAIHost
    @ObservedObject var model: ContentModel
    let probe: ContentProbe

    var body: some View {
        host.makeView { ContentSample(label: model.label, height: model.height, probe: probe) }
    }
}

private struct ContentSample: View {
    let label: String
    let height: CGFloat
    let probe: ContentProbe

    var body: some View {
        probe.label = label
        probe.renders += 1
        return Color.clear.frame(height: height)
            .background {
                GeometryReader { geometry in
                    Color.clear
                        .onAppear { probe.frameHeight = geometry.size.height }
                        .onChange(of: geometry.size.height) { probe.frameHeight = $0 }
                }
            }
    }
}
