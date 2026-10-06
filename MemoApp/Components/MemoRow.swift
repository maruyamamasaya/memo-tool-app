import SwiftUI

struct MemoRow: View {
    let memo: Memo
    @AppStorage("memoTheme") private var selectedTheme = MemoTheme.standard.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if memo.isPinned { Image(systemName: "pin.fill").font(.caption).foregroundStyle(.tint) }
                Text(memo.displayTitle).font(.headline).lineLimit(1)
                Spacer()
                Text(memo.updatedAt, format: .relative(presentation: .named).locale(Locale(identifier: "ja_JP"))).font(.caption).foregroundStyle(.secondary)
            }
            if !memo.isConfidential && !memo.content.isEmpty {
                Text(memo.content.replacingOccurrences(of: "\n", with: " "))
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            }
            HStack(spacing: 7) {
                Text(memo.usage == "temporary" ? "一時" : "保存")
                if memo.isConfidential { Label("機密", systemImage: "lock") }
                if memo.contentKind != "note" { Text(MemoInput.kindLabels[memo.contentKind] ?? "メモ") }
                if let folder = memo.folder { Label(folder.name, systemImage: "folder.fill") }
                ForEach(memo.tags.prefix(3)) { tag in Text("#\(tag.name)") }
            }
            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(.vertical, 3)
        .listRowBackground((MemoTheme(rawValue: selectedTheme) ?? .standard).surface)
    }
}
