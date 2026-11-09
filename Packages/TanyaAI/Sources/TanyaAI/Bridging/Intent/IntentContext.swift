//
//  IntentContext.swift
//  TanyaAI
//
//  Created by Gidion on 10/11/26.
//

import Foundation

/// Intent dari backend beserta parameter untuk handler terkait.
public struct IntentContext: Equatable {
    public let name: String
    public let parameters: [String: String]

    public init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
    }
}
