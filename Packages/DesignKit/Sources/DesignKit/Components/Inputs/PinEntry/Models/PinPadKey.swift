//
//  PinPadKey.swift
//  DesignKit
//
//  Created by Wendra on 16/11/26.
//

/// Satu tombol keypad `PinEntry`: angka 0–9 atau hapus satu digit terakhir.
enum PinPadKey: Hashable {
    case digit(Int)
    case delete

    /// Susunan keypad dari atas: 1–9, lalu kosong, 0, hapus. Nil = tempat kosong tanpa tombol.
    static let rows: [[PinPadKey?]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [nil, .digit(0), .delete]
    ]

    /// PIN setelah tombol ini ditekan. Angka hanya ditambah selama PIN belum sepanjang `length`; hapus pada PIN
    /// kosong tidak mengubah apa pun.
    func applied(to pin: String, length: Int) -> String {
        switch self {
        case .digit(let digit):
            guard pin.count < length else { return pin }
            return pin + String(digit)
        case .delete:
            return String(pin.dropLast())
        }
    }
}
