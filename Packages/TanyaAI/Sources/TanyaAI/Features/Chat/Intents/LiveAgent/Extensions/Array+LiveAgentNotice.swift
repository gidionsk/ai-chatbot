//
//  Array+LiveAgentNotice.swift
//  TanyaAI
//
//  Created by Wendra on 10/11/26.
//

extension Array where Element == ChatListItem {
    /// Kartu live agent di posisi `seq`-nya: tepat setelah pesan terakhir yang lebih awal, jadi tetap di hari pesan
    /// itu. Tanpa pesan yang lebih awal, kartu di awal daftar. Tombol batal ikut tepat di bawah kartu antre.
    func inserting(_ notices: [LiveAgentNotice], isLeaveEnabled: Bool) -> [ChatListItem] {
        guard !notices.isEmpty else { return self }
        let anchors = Dictionary(grouping: notices) { anchorIndex(for: $0) }
        var result = noticeItems(anchors[nil] ?? [], isLeaveEnabled: isLeaveEnabled)
        for (index, item) in enumerated() {
            result.append(item)
            result += noticeItems(anchors[index] ?? [], isLeaveEnabled: isLeaveEnabled)
        }
        return result
    }
}

// MARK: - Helpers

private extension Array where Element == ChatListItem {
    /// `<=`: kartu dari history memakai `seq` pesan yang ditutupnya, jadi tampil tepat setelah pesan itu. Kartu dari
    /// stream tidak pernah sama dengan `seq` pesan karena berbagi satu urutan.
    func anchorIndex(for notice: LiveAgentNotice) -> Int? {
        lastIndex { $0.messageSeq.map { $0 <= notice.seq } ?? false }
    }

    func noticeItems(_ notices: [LiveAgentNotice], isLeaveEnabled: Bool) -> [ChatListItem] {
        notices.flatMap { notice -> [ChatListItem] in
            let card = ChatListItem.liveAgentNotice(notice)
            return notice.kind == .connecting ? [card, .leaveAgentQueue(isEnabled: isLeaveEnabled)] : [card]
        }
    }
}

private extension ChatListItem {
    /// Urutan pesan untuk menaruh kartu. Pertanyaan lokal yang belum di-ack dianggap paling baru.
    var messageSeq: Int? {
        guard case .message(let row, _) = self else { return nil }
        switch row {
        case .message(let message):
            return message.seq
        case .local(let question):
            return question.seq ?? .max
        }
    }
}
