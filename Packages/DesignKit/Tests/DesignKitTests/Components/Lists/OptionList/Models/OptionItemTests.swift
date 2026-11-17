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
}
