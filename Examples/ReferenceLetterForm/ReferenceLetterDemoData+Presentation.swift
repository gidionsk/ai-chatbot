//
//  ReferenceLetterDemoData+Presentation.swift
//  TanyaAI
//
//  Created by Wendra on 19/11/26.
//

import UIKit

extension ReferenceLetterDemoData {
    static func presentation(for field: ReferenceLetterDemoField) -> FormFieldPresentation {
        switch field {
        case .purpose:
            return FormFieldPresentation(
                label: "Keperluan surat referensi",
                placeholder: "Pilih keperluan surat",
                requiredError: "Pilih keperluan surat referensi."
            )
        case .format:
            return FormFieldPresentation(
                label: "Format yang diinginkan",
                placeholder: "Pilih format surat",
                requiredError: "Pilih format surat."
            )
        case .embassy:
            return FormFieldPresentation(
                label: "Kedutaan/Instansi Tujuan",
                placeholder: "Masukkan kedutaan atau instansi tujuan",
                requiredError: "Kedutaan/instansi tujuan wajib diisi."
            )
        case .accounts:
            return FormFieldPresentation(
                label: "Nomor rekening yang dilampirkan",
                placeholder: "Pilih rekening",
                requiredError: "Pilih minimal satu rekening."
            )
        case .currency:
            return FormFieldPresentation(
                label: "Mata uang yang ditampilkan",
                placeholder: "Pilih mata uang",
                requiredError: "Pilih mata uang."
            )
        default:
            return supplementaryPresentation(for: field)
        }
    }

    static func selectionSummary(for field: ReferenceLetterDemoField, options: [FormOption]) -> String {
        if field == .accounts, !options.dropFirst().isEmpty {
            return "Terpilih \(options.count) rekening"
        }
        return options.map(\.title).joined(separator: ", ")
    }
}

// MARK: - Helpers

private extension ReferenceLetterDemoData {
    static func supplementaryPresentation(for field: ReferenceLetterDemoField) -> FormFieldPresentation {
        switch field {
        case .balance:
            return FormFieldPresentation(label: "Tampilkan informasi saldo", requiredError: String())
        case .investment:
            return FormFieldPresentation(label: "Tampilkan dana investasi", requiredError: String())
        case .email:
            return FormFieldPresentation(
                label: "Email pengiriman",
                requiredError: String(),
                keyboard: .emailAddress
            )
        case .address:
            return FormFieldPresentation(label: "Alamat pengiriman", requiredError: String())
        default:
            return FormFieldPresentation(label: String(), requiredError: String())
        }
    }
}
