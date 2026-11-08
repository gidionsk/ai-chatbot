//
//  MessageComposerActionTests.swift
//  DesignKitTests
//
//  Created by Wendra on 3/11/26.
//

import Testing

@testable import DesignKit

struct MessageComposerActionTests {
    @Test
    func sendShowsItsOwnIconWhenEnabledAndDisabled() {
        #expect(MessageComposerAction.send.icon(isEnabled: true) == .sendOn)
        #expect(MessageComposerAction.send.icon(isEnabled: false) == .sendOff)
    }

    /// Stopping tidak punya aset sendiri: ikon stop yang sama diredupkan sistem.
    @Test(arguments: [true, false])
    func stopAndStoppingShareThePauseIcon(isEnabled: Bool) {
        #expect(MessageComposerAction.stop.icon(isEnabled: isEnabled) == .sendPause)
        #expect(MessageComposerAction.stopping.icon(isEnabled: isEnabled) == .sendPause)
    }

    @Test
    func onlyStoppingUsesTheSystemDimming() {
        #expect(!MessageComposerAction.send.isSystemDimmed)
        #expect(!MessageComposerAction.stop.isSystemDimmed)
        #expect(MessageComposerAction.stopping.isSystemDimmed)
    }
}
