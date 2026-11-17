//
//  OptionItemTests.swift
//  DesignKitTests
//
//  Created by Wendra on 17/11/26.
//

import Testing

@testable import DesignKit

struct OptionItemTests {
    @Test
    func existingCallersCanCreateATitleOnlyOption() {
        let item = OptionItem(id: "sample-account", title: "Sample account - 1234")
        #expect(item.subtitle == nil)
    }

    @Test
    func addingASubtitlePreservesTheOptionIdentityAndTitle() {
        let item = OptionItem(id: "sample-account", title: "Sample account - 1234", subtitle: "Sample balance")
        #expect(item.id == "sample-account")
        #expect(item.title == "Sample account - 1234")
        #expect(item.subtitle == "Sample balance")
    }
}
