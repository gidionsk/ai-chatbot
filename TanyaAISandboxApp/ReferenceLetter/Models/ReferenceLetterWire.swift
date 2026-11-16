//
//  ReferenceLetterWire.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import Foundation
import TanyaAI

enum ReferenceLetterWire {
    struct Envelope<Payload: Decodable>: Decodable {
        let code: String
        let responseDescription: String?
        let responseTitle: String?
        let data: Payload?

        enum CodingKeys: String, CodingKey {
            case code = "response_code"
            case responseDescription, responseTitle, data
        }

        func message(fallback: String) -> String {
            return [responseDescription, responseTitle]
                .compactMap { $0 }.first(where: { !$0.isEmpty }) ?? fallback
        }
    }

    struct Choice: Decodable {
        let code: String
        let value: String
        let description: String?

        var option: OptionItem { OptionItem(id: code, title: value, subtitle: description) }
    }

    struct Inquiry: Decodable {
        let introduction: String
        let purposes: [Choice]
        let documentFormats: [Choice]
        let sourceAccounts: [Choice]
        let currencies: [Choice]
        let languages: [Choice]?
        let address: String
        let email: String
        let onlineSessionId: String
    }

}
