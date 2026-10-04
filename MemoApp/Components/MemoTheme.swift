import SwiftUI

enum MemoTheme: String, CaseIterable, Identifiable {
    case standard, aurora, cosmos, neon
    var id: String { rawValue }
    var name: String {
        switch self { case .standard: "標準"; case .aurora: "オーロラ"; case .cosmos: "星空"; case .neon: "ネオン" }
    }
    var subtitle: String {
        switch self {
        case .standard: "端末の外観に合わせたシンプルな表示"
        case .aurora: "紫とシアンの光が漂う、柔らかなガラス"
        case .cosmos: "たくさんの星が広がる、深い青の夜空"
        case .neon: "青とピンクの光が映る、静かな夜"
        }
    }
    var accent: Color {
        switch self { case .standard: .blue; case .aurora: Color(red: 0.48, green: 0.86, blue: 0.95); case .cosmos: Color(red: 0.65, green: 0.80, blue: 1); case .neon: Color(red: 1, green: 0.52, blue: 0.78) }
    }
    var surface: Color {
        self == .standard ? Color(uiColor: .secondarySystemGroupedBackground) : Color(red: 0.08, green: 0.11, blue: 0.20).opacity(0.78)
    }
}

struct MemoThemeBackground: View {
    let theme: MemoTheme
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 0.025, green: 0.035, blue: 0.09)
                Ellipse()
                    .fill((theme == .cosmos ? Color.blue : Color.purple).opacity(0.38))
                    .frame(width: proxy.size.width * 1.5, height: proxy.size.height * 0.52)
                    .blur(radius: 65)
                    .rotationEffect(.degrees(-30))
                    .offset(x: -proxy.size.width * 0.26, y: -proxy.size.height * 0.22)
                Ellipse()
                    .fill((theme == .neon ? Color.pink : Color.cyan).opacity(0.22))
                    .frame(width: proxy.size.width, height: proxy.size.height * 0.5)
                    .blur(radius: 75)
                    .rotationEffect(.degrees(28))
                    .offset(x: proxy.size.width * 0.3, y: proxy.size.height * 0.25)
                Canvas { context, size in
                    // Fixed seeds keep stars in place when scrolling or editing.
                    var seed: UInt64 = 20261001
                    func random() -> Double {
                        seed = (seed &* 1664525 &+ 1013904223) & 0xffffffff
                        return Double(seed) / Double(UInt32.max)
                    }
                    for index in 0..<(theme == .cosmos ? 240 : 150) {
                        let x = random() * size.width
                        let y = random() * size.height
                        let diameter = index % 37 == 0 ? 2.5 : 0.6 + random() * 1.1
                        let opacity = 0.18 + random() * 0.62
                        let rect = CGRect(x: x, y: y, width: diameter, height: diameter)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                        if index % 37 == 0 {
                            context.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)), with: .color(theme.accent.opacity(0.1)))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MemoThemeModifier: ViewModifier {
    @AppStorage("memoTheme") private var selected = MemoTheme.standard.rawValue
    private var theme: MemoTheme { MemoTheme(rawValue: selected) ?? .standard }
    @ViewBuilder func body(content: Content) -> some View {
        if theme == .standard { content }
        else {
            content
                .scrollContentBackground(.hidden)
                .background { MemoThemeBackground(theme: theme) }
                .toolbarBackground(.hidden, for: .navigationBar)
                .tint(theme.accent)
        }
    }
}

extension View {
    func memoTheme() -> some View { modifier(MemoThemeModifier()) }
}
