import SwiftUI

/// Строка метрики: SF Symbol + лейбл + значение справа (моноширинный), под ними — прогресс-бар.
/// Заливка бара скруглена на правом конце; при статусе `hot` — мягкое свечение.
struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let fraction: Double          // 0…1 заполнение бара
    let status: MetricStatus
    var accent: Color? = nil      // переопределить цвет иконки/бара (для CPU)

    private var fillColor: Color {
        // Цвет заливки = цвет статуса; но в normal можно использовать акцент метрики.
        if status == .normal, let accent { return accent }
        return status.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(accent ?? status.color)
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(status == .normal ? Color.primary : status.color)
            }
            bar
        }
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Трек.
                Capsule()
                    .fill(Color.primary.opacity(0.10))
                // Заливка: прямой левый край, скруглённый правый.
                RightRoundedRect(radius: Theme.barHeight / 2)
                    .fill(fillColor)
                    .frame(width: max(Theme.barHeight, geo.size.width * CGFloat(min(1, max(0, fraction)))))
                    .shadow(color: status == .hot ? fillColor.opacity(0.7) : .clear,
                            radius: status == .hot ? 5 : 0)
                    .animation(.easeOut(duration: 0.35), value: fraction)
            }
        }
        .frame(height: Theme.barHeight)
    }
}

/// Прямоугольник со скруглением только правого края (`border-radius: 0 99 99 0`).
struct RightRoundedRect: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r,
                 startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
