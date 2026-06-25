import SwiftUI

/// То, что рисуется в самой строке меню: иконка-пульс + настраиваемый набор значений.
/// Текст моноширинный — чтобы ширина не «прыгала».
struct MenuBarLabel: View {
    @ObservedObject var store: MetricsStore

    // Какие значения показывать рядом с иконкой (CSV из rawValue в @AppStorage).
    @AppStorage("menuBarItems") private var itemsRaw: String = MenuBarItem.cpu.rawValue

    private var items: [MenuBarItem] {
        itemsRaw.split(separator: ",").compactMap { MenuBarItem(rawValue: String($0)) }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "waveform.path.ecg")   // SF Symbol — система сама масштабирует под строку меню
            if !items.isEmpty {
                Text(text)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
        }
    }

    private var text: String {
        items.map(value(for:)).joined(separator: " ")
    }

    private func value(for item: MenuBarItem) -> String {
        switch item {
        case .cpu:  return String(format: "%.0f%%", store.cpuUsage)
        case .temp: return Fmt.temp(store.cpuTemp)
        case .ram:  return String(format: "%.0f%%", store.memory.percent)
        case .net:  return Fmt.speed(store.network.downBytesPerSec)
        }
    }
}
