//
//  HostServicesDouble.swift
//  TanyaAITests
//
//  Created by Wendra on 23/11/26.
//

@testable import TanyaAI

@MainActor
final class HostServicesDouble: TanyaAIHostServices {
    private let service: ReferenceLetterServiceDouble
    private(set) var referenceLetterReadCount = 0

    init(service: ReferenceLetterServiceDouble) {
        self.service = service
    }

    var referenceLetter: ReferenceLetterService? {
        referenceLetterReadCount += 1
        return service
    }
}
