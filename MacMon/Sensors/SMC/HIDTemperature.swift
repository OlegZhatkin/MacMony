import Foundation

/// Агрегирует показания температурных сенсоров, полученные из `HIDReader` (Apple Silicon-путь).
/// Если валидных сенсоров нет — возвращает nil (мягкая деградация).
final class HIDTemperature {
    private let reader = HIDReader()

    // Маркеры имён сенсоров CPU-кластеров на Apple Silicon.
    private static let cpuMarkers = ["CPU", "TDIE", "TCAL", "EACC", "PACC", "SOC"]

    private func snapshot() -> [(name: String, value: Double)] {
        reader.readTemperatures().compactMap { dict in
            guard let name = dict["name"] as? String,
                  let value = (dict["value"] as? NSNumber)?.doubleValue else { return nil }
            return (name, value)
        }
    }

    /// Агрегированная температура CPU (°C) или nil.
    func cpuTemperature() -> Double? {
        let all = snapshot()
        guard !all.isEmpty else { return nil }

        let cpu = all.filter { reading in
            let upper = reading.name.uppercased()
            return Self.cpuMarkers.contains { upper.contains($0) }
        }
        let pool = cpu.isEmpty ? all : cpu
        return pool.map(\.value).reduce(0, +) / Double(pool.count)
    }

    /// Отладочный дамп найденных сенсоров.
    func debugDump() {
        let all = snapshot()
        if all.isEmpty {
            print("[HIDTemperature] нет доступных температурных сенсоров")
        } else {
            for s in all { print(String(format: "[HIDTemperature] %@ = %.1f°C", s.name, s.value)) }
        }
    }
}
