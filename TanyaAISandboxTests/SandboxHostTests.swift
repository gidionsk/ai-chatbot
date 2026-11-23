//
//  SandboxHostTests.swift
//  TanyaAISandboxTests
//
//  Created by Wendra on 20/10/26.
//

import SwiftUI
import Testing
import UIKit

@testable import Tanya_AI_Sandbox

extension HostWindowTests {
    /// Host tiruan: Tanya AI dibuka lewat coordinator host dan tampil sebagai view SwiftUI biasa.
    @MainActor
    struct SandboxHostTests {
        @Test
        func tanyaAIOpensFullScreenAndClosesBackToMain() async throws {
            let host = try HostHarness()
            defer { host.close() }
            host.probe.destination = TanyaAICoordinator.named
            await waitUntil { host.navigation?.viewControllers.count == 2 }
            host.settle()
            let page = try #require(host.navigation?.topViewController)
            #expect(page.view.convert(page.view.bounds, to: nil) == host.windowBounds)
            #expect(Self.textView(in: page.view) != nil, "composer Tanya AI harus ada di halaman yang di-push")
            host.probe.destination = nil
            await waitUntil { host.navigation?.viewControllers.count == 1 }
        }

        @Test
        func parentRerenderKeepsTheOpenPage() async throws {
            let host = try HostHarness()
            defer { host.close() }
            host.probe.destination = TanyaAICoordinator.named
            await waitUntil { host.navigation?.viewControllers.count == 2 }
            host.settle()
            let page = try #require(host.navigation?.topViewController)
            host.probe.tick += 1
            host.settle()
            #expect(host.navigation?.topViewController === page)
            #expect(host.navigation?.viewControllers.count == 2)
        }

        /// Transport host melapor ke blocker host saat kirim gagal tanpa internet; retry menutup blocker.
        @Test
        func offlineSendShowsTheHostBlocker() async {
            let options = SandboxOptions(arguments: ["--offline"])
            let offline = TanyaAIScreenViewModel(useCase: TanyaAIUseCase(options: options))
            _ = try? await offline.useCase.sendMessage(conversationID: "c", clientMessageID: "c-1", text: "Halo")
            #expect(offline.isNetworkUnavailable)
            offline.retry()
            #expect(!offline.isNetworkUnavailable)
        }

        @Test
        func popGestureNeedsAPageToReturnTo() throws {
            let navigation = UINavigationController(rootViewController: UIViewController())
            let fixture = try HostWindowFixture(root: navigation)
            defer { fixture.close() }
            let swipe = try #require(navigation.interactivePopGestureRecognizer)
            #expect(!navigation.gestureRecognizerShouldBegin(swipe))
            navigation.pushViewController(UIViewController(), animated: false)
            fixture.settle()
            #expect(navigation.gestureRecognizerShouldBegin(swipe))
        }
    }
}

private extension HostWindowTests.SandboxHostTests {
    /// Editor composer Tanya AI berupa UITextView, jadi bisa dicari langsung di hierarki halaman.
    static func textView(in root: UIView) -> UITextView? {
        if let textView = root as? UITextView { return textView }
        return root.subviews.lazy.compactMap { textView(in: $0) }.first
    }
}

/// Main tiruan dengan destinasi detail yang dikendalikan test.
@MainActor
private final class HostHarness {
    let appState = AppState()
    let probe = DestinationProbe()
    private let fixture: HostWindowFixture

    init() throws {
        fixture = try HostWindowFixture(HarnessMain(probe: probe).environmentObject(appState))
        settle()
    }

    var windowBounds: CGRect { fixture.controller.view.window?.bounds ?? .zero }
    var navigation: UINavigationController? { Self.find(UINavigationController.self, in: fixture.controller) }

    func settle() {
        fixture.settle()
        fixture.settle()
    }

    func close() {
        fixture.close()
    }

    private static func find<Controller: UIViewController>(_ type: Controller.Type, in controller: UIViewController)
        -> Controller?
    {
        if let match = controller as? Controller { return match }
        return controller.children.lazy.compactMap { find(type, in: $0) }.first
    }
}

private final class DestinationProbe: ObservableObject {
    @Published
    var destination: String?
    @Published
    var tick = 0
}

/// Sama dengan `MainCoordinator`, tetapi tujuan dikendalikan test.
private struct HarnessMain: View {
    @ObservedObject
    var probe: DestinationProbe
    @StateObject
    private var viewModel = MainScreenViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                if probe.destination == TanyaAICoordinator.named {
                    TanyaAICoordinator(selectionCoordinatorName: $probe.destination, greeting: .init(), shortcuts: [])
                }
                Screen { MainScreen(viewModel: viewModel, onOpenDetail: {}, onOpenTanyaAI: {}) }
                Text(String(probe.tick))
            }
        }
        .navigationViewStyle(.stack)
    }
}
