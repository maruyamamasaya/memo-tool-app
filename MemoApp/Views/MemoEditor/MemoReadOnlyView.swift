import SwiftUI
import WebKit

struct MemoReadOnlyView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let content: String
    let format: String

    var body: some View {
        NavigationStack {
            Group {
                if format.lowercased() == "md" {
                    MarkdownWebView(markdown: "# \(title)\n\n\(content)")
                } else {
                    ScrollView {
                        Text([title, content].filter { !$0.isEmpty }.joined(separator: "\n\n"))
                            .font(.body.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                    }
                }
            }
            .navigationTitle("表示のみ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

private struct MarkdownWebView: UIViewRepresentable {
    let markdown: String

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
        webView.loadHTMLString(MarkdownHTMLRenderer.document(from: markdown), baseURL: nil)
    }
}

private enum MarkdownHTMLRenderer {
    static func document(from markdown: String) -> String {
        let body = blocks(from: markdown.replacingOccurrences(of: "\r", with: ""))
        return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <style>
        :root{color-scheme:light dark} body{font:17px -apple-system,BlinkMacSystemFont,sans-serif;line-height:1.65;margin:0;padding:20px;color:CanvasText;background:Canvas}
        h1,h2,h3,h4,h5,h6{line-height:1.25;margin:1.25em 0 .5em} h1{font-size:2em;border-bottom:1px solid #8885;padding-bottom:.25em}
        pre,code{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;background:#8882;border-radius:6px} code{padding:.15em .35em} pre{padding:14px;overflow:auto} pre code{padding:0;background:none}
        blockquote{margin:1em 0;padding:.1em 1em;border-left:4px solid #8888;color:#777} img{max-width:100%} a{color:#1677d2} hr{border:0;border-top:1px solid #8886}
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
