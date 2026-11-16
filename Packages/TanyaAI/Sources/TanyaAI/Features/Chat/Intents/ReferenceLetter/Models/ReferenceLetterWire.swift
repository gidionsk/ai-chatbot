//
//  ReferenceLetterWire.swift
//  TanyaAI
//
//  Created by Wendra on 16/11/26.
//

import DesignKit
import Foundation

enum ReferenceLetterWire {
    struct Envelope<Payload: Decodable>: Decodable {
        let code: String
        let responseDescription: String?
        let responseTitle: String?
        let descriptionEnglish: String?
        let descriptionIndonesian: String?
        let data: Payload?

        enum CodingKeys: String, CodingKey {
            case code = "response_code"
            case descriptionEnglish = "response_desc_en"
            case descriptionIndonesian = "response_desc_id"
            case responseDescription, responseTitle, data
        }

        func message(locale: Locale, fallback: String) -> String {
            let localized = locale.languageCode == "id" ? descriptionIndonesian : descriptionEnglish
            return [localized, responseDescription, responseTitle]
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

    struct Receipt: Decodable {
        let title: String
        let message: String
    }

    struct Empty: Decodable {}
}
