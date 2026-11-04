//
//  MarkdownParserTests.swift
//  DesignKitTests
//
//  Created by Wendra on 3/11/26.
//

import Foundation
import Testing

@testable import DesignKit

/// Struktur blok dari parser Apple: nesting, nomor list, perataan tabel, dan isi code block.
struct MarkdownParserTests {
    @Test
    func headingParagraphAndDividerKeepTheirOrder() {
        let blocks = MarkdownDocument("# Kurs\nBaris satu\nbaris dua\n\n---\n\nAkhir").blocks
        #expect(blocks.count == 4)
        #expect(blocks.first == .heading(level: 1, text: AttributedString("Kurs")))
        #expect(plain(blocks[1]) == "Baris satu baris dua")
        #expect(blocks[2] == .divider)
    }

    @Test
    func nestedListsKeepOrdinalsAndDepth() throws {
        let blocks = MarkdownDocument("- satu\n- dua\n  1. tiga\n  2. empat").blocks
        guard case .list(let outer) = try #require(blocks.first) else { return #expect(Bool(false)) }
        #expect(!outer.isOrdered)
        #expect(outer.items.map(\.ordinal) == [1, 2])
        guard case .list(let inner) = try #require(outer.items.last?.blocks.last) else {
            return #expect(Bool(false))
        }
        #expect(inner.isOrdered)
        #expect(inner.items.map(\.ordinal) == [1, 2])
    }

    /// List bernomor boleh mulai dari angka selain 1 (CommonMark: hanya di awal blok, bukan memotong paragraf).
    @Test
    func orderedListKeepsItsStartNumber() throws {
        guard case .list(let list) = try #require(MarkdownDocument("3. tiga\n4. empat").blocks.first) else {
            return #expect(Bool(false))
        }
        #expect(list.items.map(\.ordinal) == [3, 4])
    }

    @Test
    func quoteContainsItsOwnBlocks() throws {
        let blocks = MarkdownDocument("> kutipan\n> - butir").blocks
        guard case .quote(let inner) = try #require(blocks.first) else { return #expect(Bool(false)) }
        #expect(inner.count == 2)
        #expect(plain(inner[0]) == "kutipan")
    }

    @Test
    func codeBlockKeepsIndentationWithoutTrailingNewline() {
        let blocks = MarkdownDocument("```swift\nif a {\n    b()\n}\n```").blocks
        #expect(blocks == [.code("if a {\n    b()\n}")])
    }

    /// Sel yang hilang diisi kosong, jadi setiap baris selebar jumlah kolom.
    @Test
    func tableKeepsAlignmentsHeaderAndPadsMissingCells() throws {
        let markdown = "| Mata uang | Jual | Beli |\n|:---|:---:|---:|\n| USD | 16.250 |\n| SGD | 12.000 | 11.900 |"
        guard case .table(let table) = try #require(MarkdownDocument(markdown).blocks.first) else {
            return #expect(Bool(false))
        }
        #expect(table.alignments == [.leading, .center, .trailing])
        #expect(table.header.map { String($0.characters) } == ["Mata uang", "Jual", "Beli"])
        #expect(
            table.rows.map { $0.map { String($0.characters) } } == [["USD", "16.250", ""], ["SGD", "12.000", "11.900"]])
    }

    /// `[ ]`/`[x]` menjadi status dan tidak tampil sebagai teks; yang bukan task tetap item biasa.
    @Test
    func taskItemsBecomeStatesAndLoseTheirPrefix() throws {
        let markdown = "- [ ] belum\n- [x] **sudah**\n- [X] besar\n- biasa\n- [y] bukan task"
        guard case .list(let list) = try #require(MarkdownDocument(markdown).blocks.first) else {
            return #expect(Bool(false))
        }
        #expect(list.items.map(\.task) == [.open, .done, .done, nil, nil])
        #expect(
            list.items.compactMap { $0.blocks.first.flatMap(plain) } == [
                "belum", "sudah", "besar", "biasa", "[y] bukan task"
            ])
    }

    /// Gambar dikeluarkan dari paragraf berurutan, tanpa paragraf kosong dan tanpa spasi tersisa.
    @Test
    func imagesSplitParagraphsInOrder() throws {
        let url = try #require(URL(string: "https://ocbc.id/a.png"))
        let solo = MarkdownDocument("![kurs](https://ocbc.id/a.png)").blocks
        let mixed = MarkdownDocument("Sebelum ![kurs](https://ocbc.id/a.png) sesudah").blocks
        #expect(solo == [.image(url: url, alt: "kurs")])
        #expect(mixed.count == 3)
        #expect(plain(mixed[0]) == "Sebelum")
        #expect(mixed[1] == .image(url: url, alt: "kurs"))
        #expect(plain(mixed[2]) == "sesudah")
    }

    /// Item list dan quote memakai pemetaan blok yang sama.
    @Test
    func imagesAndTasksWorkInsideContainers() throws {
        let url = try #require(URL(string: "https://ocbc.id/a.png"))
        guard case .list(let list) = try #require(MarkdownDocument("- ![a](https://ocbc.id/a.png)").blocks.first),
            case .quote(let quoted) = try #require(MarkdownDocument("> ![a](https://ocbc.id/a.png)").blocks.first)
        else { return #expect(Bool(false)) }
        #expect(list.items.first?.blocks == [.image(url: url, alt: "a")])
        #expect(quoted == [.image(url: url, alt: "a")])
    }

    /// Teks biasa (termasuk tanda bintang tunggal pada nomor kartu) tetap satu paragraf.
    @Test
    func plainTextStaysOneParagraph() {
        let blocks = MarkdownDocument("Kartu 5521 **** 1234 aktif").blocks
        #expect(blocks.count == 1)
        #expect(plain(blocks[0]) == "Kartu 5521 **** 1234 aktif")
    }
}

// MARK: - Helpers

private extension MarkdownParserTests {
    func plain(_ block: MarkdownBlock) -> String? {
        guard case .paragraph(let text) = block else { return nil }
        return String(text.characters)
    }
}
