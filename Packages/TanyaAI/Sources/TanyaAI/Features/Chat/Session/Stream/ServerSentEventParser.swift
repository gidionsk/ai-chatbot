//
//  ServerSentEventParser.swift
//  TanyaAI
//
//  Created by Wendra on 28/10/26.
//

import Foundation

/// Menyusun baris SSE menjadi frame. Contract 1.0.1: urutan `id:`, `event:`, `data:` dengan `data` JSON satu
/// baris, jadi frame selesai tepat di baris `data:`. Tidak bergantung pada baris kosong (host boleh
/// membuangnya), sehingga `turn_end` terakhir tidak tertahan sampai event berikutnya. Komentar diabaikan.
struct ServerSentEventParser {
    private var eventID: String?
    private var name: String?
    private var data: String?

    /// Satu baris tanpa newline; mengembalikan frame yang selesai karena baris ini, bila ada.
    mutating func consume(_ line: String) -> ServerSentEvent? {
        let line = line.trimmingCharacters(in: .newlines)
        if line.isEmpty {
            return flush()
        }
        if line.hasPrefix(ChatWire.commentPrefix) {
            return nil
        }
        if let value = Self.value(of: line, field: ChatWire.idField) {
            eventID = value
        } else if let value = Self.value(of: line, field: ChatWire.eventField) {
            name = value
        } else if let value = Self.value(of: line, field: ChatWire.dataField) {
            data = value
            return flush()
        }
        return nil
    }

    /// Menutup frame yang sedang disusun; nil bila belum ada `data:`.
    private mutating func flush() -> ServerSentEvent? {
        defer { self = Self() }
        guard let data else { return nil }
        return ServerSentEvent(id: eventID, name: name ?? ChatWire.Event.message, data: data)
    }
}

// MARK: - Helpers

private extension ServerSentEventParser {
    static func value(of line: String, field: String) -> String? {
        guard line.hasPrefix(field) else { return nil }
        let value = line.dropFirst(field.count)
        return String(value.hasPrefix(ChatWire.fieldValueSpace) ? value.dropFirst() : value)
    }
}
