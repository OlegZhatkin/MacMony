import SwiftUI

/// Палитра, материалы и константы стиля.
enum Theme {
    // Статусы.
    static let normal = Color(hex: 0x6FE0B8)   // teal/green
    static let warm   = Color(hex: 0xFFB84D)   // amber
    static let hot     = Color(hex: 0xFF6B5D)   // red

    // Акценты.
    static let cpuAccent  = Color(hex: 0x5DB0FF)
    static let ramAccent  = Color(hex: 0x6FE0B8)
    static let netDown    = Color(hex: 0x7FC0FF)
    static let netUp      = Color(hex: 0xFF9D7A)
    static let rocket     = Color(hex: 0xFF9D7A)
    static let clock      = Color(hex: 0x5DB0FF)

    // Геометрия.
    static let popoverWidth: CGFloat = 360
    static let barHeight: CGFloat = 7
    static let cardCorner: CGFloat = 20

    /// Градиентный фон окна (тёмный navy → purple).
    static let bgGradient = LinearGradient(
        colors: [Color(hex: 0x1C2438), Color(hex: 0x2A2036)],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    /// Градиент шкалы температуры (норма → warm → hot).
    static let tempGradient = LinearGradient(
        colors: [normal, normal, warm, hot],
        startPoint: .leading, endPoint: .trailing)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red:   Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue:  Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}

/// Стеклянная карточка-контейнер (liquid glass) с тонким верхним хайлайтом.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                        .fill(.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: Theme.cardCorner, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.22), .white.opacity(0.04)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 1)
                }
            )
    }
}
