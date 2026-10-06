import Foundation

enum MemoInput {
    static let kindLabels = ["note": "メモ", "prompt": "プロンプト", "command": "コマンド", "code": "コード"]
    static func parse(_ text: String, format: String) -> (title: String, body: String, tags: [String], format: String) {
        var lines = text.components(separatedBy: "\n")
        var title = (lines.isEmpty ? "" : lines.removeFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        var format = format
        if let match = title.range(of: #"\.(md|txt)$"#, options: [.regularExpression, .caseInsensitive]) {
            format = String(title[match]).dropFirst().lowercased(); title.removeSubrange(match)
        }
        var tags: [String] = []
        if let last = lines.last, last.trimmingCharacters(in: .whitespaces).hasPrefix("#") { lines.removeLast(); tags = parseTags(last) }
        return (String(title.prefix(120)), lines.joined(separator: "\n"), tags, format)
    }
    static func parseTags(_ text: String) -> [String] {
        var result: [String] = []
        for part in text.components(separatedBy: .whitespacesAndNewlines.union(.init(charactersIn: ",、"))) {
            let tag = part.hasPrefix("#") ? String(part.dropFirst()) : part
            if !tag.isEmpty && !result.contains(tag) && result.count < 20 { result.append(tag) }
        }
        return result
    }
}
