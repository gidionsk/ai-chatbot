//
//  FormOption.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Data pilihan dari host, dipakai bersama oleh intent form. Tidak bergantung pada komponen UI.
public struct FormOption: Equatable {
    public let code: String
    public let title: String
    public let subtitle: String?

    public init(code: String, title: String, subtitle: String? = nil) {
        self.code = code
        self.title = title
        self.subtitle = subtitle
    }
}
