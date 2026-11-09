//
//  IntentHandler.swift
//  TanyaAI
//
//  Created by Gidion on 10/11/26.
//

/// Penanganan intent khusus domain yang didaftarkan oleh host.
@MainActor
public protocol IntentHandler: AnyObject {
    var intentName: String { get }
    func handle(_ context: IntentContext) -> IntentResult
}
