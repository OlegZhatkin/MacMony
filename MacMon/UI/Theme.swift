import SwiftUI

/// Палитра, материалы и константы стиля.
enum Theme {
    // Статусы.
    static let normal = Color(hex: 0x6FE0B8)   // teal/green
    static let warm   = Color(hex: 0xFFB84D)   // amber
    static let hot     = Color(hex: 0xFF6B5D)   // red

    // Акценты.
    static let cpuAccent  = Color(hex: 0x5DB0FF)
    static let netDown    = Color(hex: 0x7FC0FF)
    static let netUp      = Color(hex: 0xFF9D7A)

    // Геометрия.
    static let popoverWidth: CGFloat = 340
    static let barHeight: CGFloat = 7
    static let corner: CGFloat = 16
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
