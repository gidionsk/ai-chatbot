//
//  ReferenceLetterFormTests.swift
//  TanyaAITests
//
//  Created by Wendra on 22/11/26.
//

import Foundation
import Testing

@testable import TanyaAI

@MainActor
struct ReferenceLetterFormTests {
    @Test
    func loadingAndCancellationPublishLayout() async throws {
        let service = ReferenceLetterServiceDouble()
        var layouts: [ReferenceLetterLayout] = []
        let form = ReferenceLetterForm(service: service) { _, layout in layouts.append(layout) }
        #expect(form.layout == .loading)
        await form.load()
        #expect(form.introduction != nil)
        #expect(form.inquiry != nil)
        #expect(layouts == [.form(fields: form.draft.visibleFields.map(\.id), invalid: [])])
        await form.load()
        #expect(service.inquiryCount == 1)

        form.draft[text: .embassy] = "Some text"
        #expect(layouts.count == 1, "Typing text alone should not reconfigure the table")
        form.draft.select(["HARDCOPY"], for: .format)
        let isValid = form.draft.validate()
        #expect(!isValid)
        #expect(layouts.count == 3)
        #expect(layouts.last == .form(fields: form.draft.visibleFields.map(\.id), invalid: [.accounts, .currency]))
        form.cancel()
        #expect(layouts.last == .cancelled)
        #expect(form.inquiry == nil)
        #expect(form.draft.visibleFields.isEmpty)
    }

    @Test
    func failedInquiryHidesTheCard() async {
        let service = ReferenceLetterServiceDouble()
        service.inquiryResult = .failure(URLError(.badServerResponse))
        let form = ReferenceLetterForm(service: service)
        await form.load()
        #expect(form.layout == .hidden)
        #expect(form.inquiry == nil)
        #expect(form.draft.visibleFields.isEmpty)
    }

    @Test
    func invalidPINOrDraftNeverCallsHost() async throws {
        let service = ReferenceLetterServiceDouble()
        let form = ReferenceLetterForm(service: service)
        await form.load()
        let invalidDraft = try await form.submit(pin: "123456")
        #expect(invalidDraft == nil)
        ReferenceLetterServiceDouble.fill(form)
        let shortPIN = try await form.submit(pin: "12345")
        let nonNumeric = try await form.submit(pin: "abc123")
        #expect(shortPIN == nil)
        #expect(nonNumeric == nil)
        #expect(service.submitCount == 0)
    }

    @Test
    func successClearsTheDraftAndShowsACK() async throws {
        let service = ReferenceLetterServiceDouble()
        let form = ReferenceLetterForm(service: service)
        await form.load()
        ReferenceLetterServiceDouble.fill(form)
        let receipt = try await form.submit(pin: "123456")
        #expect(receipt?.successID == "ref-1")
        #expect(form.layout == .submitted)
        #expect(form.acknowledgement != nil)
        #expect(form.inquiry == nil)
        #expect(form.draft.visibleFields.isEmpty)
    }

    @Test(arguments: [false, true])
    func verificationFailureStaysOnPIN(isBlocked: Bool) async throws {
        let service = ReferenceLetterServiceDouble()
        let form = ReferenceLetterForm(service: service)
        await form.load()
        ReferenceLetterServiceDouble.fill(form)
        service.submitResult = .failure(
            ReferenceLetterSubmissionError.pinVerification(
                message: "Safe PIN error",
                isBlocked: isBlocked
            ))
        let result = try await form.submit(pin: "123456")
        #expect(result == nil)
        #expect(form.pinError != nil)
        #expect(form.isPINBlocked == isBlocked)
        #expect(service.displayedErrors.isEmpty)
        form.clearSubmissionError()
        #expect((form.pinError != nil) == isBlocked)
        if isBlocked {
            let blocked = try await form.submit(pin: "123456")
            #expect(blocked == nil)
            #expect(service.submitCount == 1)
        }
    }

    @Test
    func ackFailureIsForwardedAfterClose() async {
        let service = ReferenceLetterServiceDouble()
        let form = ReferenceLetterForm(service: service)
        await form.load()
        ReferenceLetterServiceDouble.fill(form)
        service.submitResult = .failure(ReferenceLetterSubmissionError.acknowledgement(URLError(.badServerResponse)))
        do {
            _ = try await form.submit(pin: "123456")
            Issue.record("Expected an ACK failure")
        } catch ReferenceLetterSubmissionError.acknowledgement(let cause) {
            #expect(form.pinError == nil)
            #expect(service.displayedErrors.isEmpty)
            form.presentAcknowledgementError(cause)
            #expect((service.displayedErrors.first as? URLError)?.code == .badServerResponse)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
