//
//  FormField.swift
//  TanyaAI
//
//  Created by Wendra on 17/11/26.
//

/// Definisi data field milik intent. Label, keyboard dan tampilan tetap ditentukan pemakai komponen DesignKit.
struct FormField<FieldID: Hashable> {
    let id: FieldID
    let initialValue: FormFieldValue
    let options: [FormOption]
    let isRequired: Bool
    let isEnabled: Bool
    let condition: FormFieldCondition<FieldID>?

    init(
        id: FieldID,
        initialValue: FormFieldValue,
        options: [FormOption] = [],
        isRequired: Bool = false,
        isEnabled: Bool = true,
        condition: FormFieldCondition<FieldID>? = nil
    ) {
        self.id = id
        self.initialValue = initialValue
        var seenCodes = Set<String>()
        // Data host bisa berisi kode kosong atau ganda; sheet dan ringkasan memakai daftar bersih yang sama.
        self.options = options.filter { !$0.code.isEmpty && seenCodes.insert($0.code).inserted }
        self.isRequired = isRequired
        self.isEnabled = isEnabled
        self.condition = condition
    }
}
