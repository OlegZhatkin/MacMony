import SwiftUI

/// Цветовой статус метрики: зелёный / янтарный / красный.
enum MetricStatus {
    case normal, warm, hot

    var color: Color {
        switch self {
        case .normal: return Theme.normal
        case .warm:   return Theme.warm
        case .hot:    return Theme.hot
        }
    }

    /// Статус по проценту (0…100) с настраиваемыми порогами warm/hot.
    static func by(percent: Double, warm: Double, hot: Double) -> MetricStatus {
        if percent >= hot { return .hot }
        if percent >= warm { return .warm }
        return .normal
    }
}

/// Одно показание вентилятора.
struct FanReading: Identifiable, Equatable {
    let index: Int
    let current: Int
    let min: Int
    let max: Int

    var id: Int { index }

    /// Заполненность диапазона 0…1 (для бара).
    var fraction: Double {
        guard max > min else { return 0 }
        return Swift.max(0, Swift.min(1, Double(current - min) / Double(max - min)))
    }

    var status: MetricStatus {
        MetricStatus.by(percent: fraction * 100, warm: 70, hot: 90)
    }
}

/// Какие значения показывать в самой строке меню рядом с иконкой.
enum MenuBarItem: String, CaseIterable, Identifiable {
    case cpu, temp, ram, net
    var id: String { rawValue }
    var title: String {
        switch self {
        case .cpu:  return "CPU %"
        case .temp: return "Температура"
        case .ram:  return "RAM %"
        case .net:  return "Сеть ↓"
        }
    }
}

/// Интервал опроса в секундах.
enum PollInterval: Double, CaseIterable, Identifiable {
    case one = 1, two = 2, five = 5
    var id: Double { rawValue }
    var label: String { rawValue == 1 ? "1 с" : "\(Int(rawValue)) с" }
}

/// Утилиты форматирования.
enum Fmt {
    /// Байты/с → человекочитаемая скорость.
    static func speed(_ bytesPerSec: Double) -> String {
        let b = max(0, bytesPerSec)
        if b < 1024 { return String(format: "%.0f B/s", b) }
        let kb = b / 1024
        if kb < 1024 { return String(format: "%.1f KB/s", kb) }
        let mb = kb / 1024
        if mb < 1024 { return String(format: "%.1f MB/s", mb) }
        return String(format: "%.1f GB/s", mb / 1024)
    }

    static func gb(_ bytes: Double) -> String {
        String(format: "%.1f GB", bytes / 1_073_741_824)
    }

    static func temp(_ c: Double?) -> String {
        guard let c else { return "—" }
        return String(format: "%.0f°", c)
    }
}
