import Foundation

struct SMCReading {
    var cpuTemperature: Double?
    var fans: [FanReading]
}

/// Высокоуровневый фасад датчиков термоконтроллера:
///   - температура CPU — через HID Event System (Apple Silicon-путь, `HIDReader`),
///   - вентиляторы — через AppleSMC IOKit (`SMCFanReader`, ключи FNum / F0Ac / F0Mn / F0Mx).
/// Любой недоступный источник деградирует мягко: nil / пустой массив.
final class SMCService {
    private let hid = HIDTemperature()
    private let smc = SMCFanReader()
    private var smcOpen = false
    private var didDump = false

    init() {
        smcOpen = smc.open()
    }

    deinit { smc.close() }

    /// Один опрос. Дороже остальных метрик — вызывать можно реже.
    func read() -> SMCReading {
        let temp = hid.cpuTemperature()
        let fans = smcOpen ? readFans() : []

        // Разовый дамп доступных сенсоров в консоль для отладки на конкретной модели.
        if !didDump {
            didDump = true
            hid.debugDump()
            if fans.isEmpty {
                print("[SMCService] вентиляторы не обнаружены (норма для MacBook Air и др.)")
            } else {
                print("[SMCService] вентиляторов: \(fans.count); первый: \(fans[0].current) RPM (\(fans[0].min)…\(fans[0].max))")
            }
            let tStr = temp.map { String(format: "%.1f°C", $0) } ?? "—"
            print("[SMCService] cpuTemp=\(tStr) smcOpen=\(smcOpen)")
            fflush(stdout)
        }
        return SMCReading(cpuTemperature: temp, fans: fans)
    }

    private func readFans() -> [FanReading] {
        smc.readFans().enumerated().map { idx, dict in
            FanReading(index: idx,
                       current: dict["current"]?.intValue ?? 0,
                       min: dict["min"]?.intValue ?? 0,
                       max: dict["max"]?.intValue ?? 1)
        }
    }
}
