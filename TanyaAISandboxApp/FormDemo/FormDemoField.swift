//
//  FormDemoField.swift
//  TanyaAISandboxApp
//
//  Created by Wendra on 12/11/26.
//

/// Field form contoh yang bisa tidak valid, urut dari atas ke bawah seperti di layar.
enum FormDemoField: CaseIterable {
    case format
    case accounts
    case address

    /// Field pilihan membuka sheet-nya sendiri saat tidak valid; field teks tidak punya sheet.
    var sheet: FormDemoSheet? {
        switch self {
        case .format:
            return .format
        case .accounts:
            return .accounts
        case .address:
            return nil
        }
    }
}
