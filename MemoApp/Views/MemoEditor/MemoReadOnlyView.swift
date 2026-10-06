import SwiftUI
import WebKit
import UIKit

struct MemoReadOnlyView: View {
    @AppStorage("memoTheme") private var selectedTheme = MemoTheme.standard.rawValue
    private let memo: Memo?
    private let previewTitle: String
    private let previewContent: String
    private let previewFormat: String
    @State private var showingEditor = false
    @State private var didCopy = false

    private var title: String { memo?.title ?? previewTitle }
    private var content: String { memo?.content ?? previewContent }
    private var format: String { memo?.format ?? previewFormat }
    private var plainText: String {
        [title, content].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    init(memo: Memo) {
        self.memo = memo
        previewTitle = ""
        previewContent = ""
        previewFormat = "txt"
    }

    init(title: String, content: String, format: String) {
        memo = nil
        previewTitle = title
        previewContent = content
        previewFormat = format
    }

    var body: some View {
        NavigationStack {
            Group {
                if format.lowercased() == "md" && !["command", "code"].contains(memo?.contentKind ?? "note") {
                    MarkdownWebView(markdown: "# \(title)\n\n\(content)", themed: selectedTheme != MemoTheme.standard.rawValue)
                } else {
                    ScrollView {
                        Text(plainText)
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                    }
                }
            }
            .memoTheme()
            .navigationTitle("表示のみ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if memo != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("編集") { showingEditor = true }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(didCopy ? "コピーしました" : "コピー") {
                        UIPasteboard.general.string = content
                        didCopy = true
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                if let memo { MemoEditorView(memo: memo) }
            }
            .onChange(of: plainText) { _, _ in didCopy = false }
        }
    }
}

private struct MarkdownWebView: UIViewRepresentable {
    let markdown: String
    let themed: Bool

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.scrollView.backgroundColor = .clear
        return view
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(MarkdownHTMLRenderer.document(from: markdown, themed: themed), baseURL: nil)
    }
}

private enum MarkdownHTMLRenderer {
    static func document(from markdown: String, themed: Bool) -> String {
        let body = blocks(from: markdown.replacingOccurrences(of: "\r", with: ""))
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        :root{color-scheme:light dark} body{font:17px -apple-system,BlinkMacSystemFont,sans-serif;line-height:1.65;margin:0;padding:20px;color:\(themed ? "#edf2ff" : "CanvasText");background:\(themed ? "transparent" : "Canvas")}
        h1,h2,h3,h4,h5,h6{line-height:1.25;margin:1.25em 0 .5em} h1{font-size:2em;border-bottom:1px solid #8885;padding-bottom:.25em}
        pre,code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;background:#8882;border-radius:6px} code{padding:.15em .35em} pre{padding:14px;overflow:auto} pre code{padding:0;background:none}
        blockquote{margin:1em 0;padding:.1em 1em;border-left:4px solid #8888;color:#777} img{max-width:100%} a{color:#1677d2} hr{border:0;border-top:1px solid #8886}
        @media(max-width:700px){body{font-size:14px;line-height:1.6;padding:16px}h1{font-size:1.35em}h2{font-size:1.2em}h3{font-size:1.1em}h4,h5,h6{font-size:1em}h1,h2,h3,h4,h5,h6{margin:1.1em 0 .5em}p,ul,ol,pre,blockquote{margin:.8em 0}li+li{margin-top:.2em}pre{padding:12px}body>:first-child{margin-top:0}}
        </style></head><body>\(body)</body></html>
        """
    }

    private static func blocks(from source: String) -> String {
        let lines = source.components(separatedBy: "\n")
        var html: [String] = []
        var paragraph: [String] = []
        var listItems: [String] = []
        var codeLines: [String] = []
        var inCode = false

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            html.append("<p>\(paragraph.map(inline).joined(separator: "<br>"))</p>")
            paragraph.removeAll()
        }
        func flushList() {
            guard !listItems.isEmpty else { return }
            html.append("<ul>\(listItems.map { "<li>\(inline($0))</li>" }.joined())</ul>")
            listItems.removeAll()
        }

        for line in lines {
            if line.hasPrefix("```") {
                flushParagraph(); flushList()
                if inCode {
                    html.append("<pre><code>\(escape(codeLines.joined(separator: "\n")))</code></pre>")
                    codeLines.removeAll()
                }
                inCode.toggle()
                continue
            }
            if inCode { codeLines.append(line); continue }
            if line.trimmingCharacters(in: .whitespaces).isEmpty { flushParagraph(); flushList(); continue }
            if let heading = heading(line) { flushParagraph(); flushList(); html.append(heading); continue }
            if line == "---" || line == "***" { flushParagraph(); flushList(); html.append("<hr>"); continue }
            if line.hasPrefix("> ") { flushParagraph(); flushList(); html.append("<blockquote>\(inline(String(line.dropFirst(2))))</blockquote>"); continue }
            if line.hasPrefix("- ") || line.hasPrefix("* ") { flushParagraph(); listItems.append(String(line.dropFirst(2))); continue }
            flushList(); paragraph.append(line)
        }
        if inCode { html.append("<pre><code>\(escape(codeLines.joined(separator: "\n")))</code></pre>") }
        flushParagraph(); flushList()
        return html.joined(separator: "\n")
    }

    private static func heading(_ line: String) -> String? {
        let count = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(count), line.dropFirst(count).hasPrefix(" ") else { return nil }
        return "<h\(count)>\(inline(String(line.dropFirst(count + 1))))</h\(count)>"
    }

    private static func inline(_ value: String) -> String {
        var result = escape(value)
        let replacements = [
            (#"`([^`]+)`"#, "<code>$1</code>"),
            (#"\*\*([^*]+)\*\*"#, "<strong>$1</strong>"),
            (#"\*([^*]+)\*"#, "<em>$1</em>"),
            (#"\[([^]]+)\]\((https?://[^ )]+)\)"#, "<a href=\"$2\">$1</a>")
        ]
        for (pattern, replacement) in replacements {
            result = result.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        return result
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
