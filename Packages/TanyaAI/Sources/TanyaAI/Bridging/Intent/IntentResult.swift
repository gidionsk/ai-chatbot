//
//  IntentResult.swift
//  TanyaAI
//
//  Created by Gidion on 10/11/26.
//

/// Keputusan handler; host menangani navigasi, sedangkan UI inline diintegrasikan kemudian.
public enum IntentResult: Equatable {
    case navigate(IntentContext)
    case render(IntentContext)
    case unsupported
}
