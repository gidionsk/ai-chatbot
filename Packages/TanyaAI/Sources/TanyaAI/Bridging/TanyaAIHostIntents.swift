//
//  TanyaAIHostIntents.swift
//  TanyaAI
//
//  Created by Wendra on 23/11/26.
//

/// Kontrak opsional untuk use case host yang juga diberikan sebagai `TanyaAIChatTransport`.
/// Bridge membaca konfigurasi sekali saat menyiapkan atau menampilkan intent yang memerlukan service host.
@MainActor
public protocol TanyaAIHostIntents: AnyObject {
    var intentServices: TanyaAIIntentServices { get }
}
