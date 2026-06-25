import SwiftUI
import Combine

/// Владелец метрик и таймера. Сенсоры читаются в фоне, публикация — на главном потоке.
@MainActor
final class MetricsStore: ObservableObject {
    // Опубликованные метрики — SwiftUI перерисовывает сам.
    @Published var cpuUsage: Double = 0          // %
    @Published var memory = MemoryReading(usedBytes: 0, totalBytes: 0)
    @Published var network = NetworkReading(downBytesPerSec: 0, upBytesPerSec: 0)
    @Published var cpuTemp: Double? = nil         // °C
    @Published var fans: [FanReading] = []

    // Настройки, влияющие на опрос.
    @AppStorage("pollInterval") var pollIntervalRaw: Double = PollInterval.two.rawValue {
        didSet { restartTimer() }
    }
    @AppStorage("tempThreshold") var tempThreshold: Double = 85   // граница warm/hot, °C

    // Сенсоры. Доступ к ним сериализован через `workQueue` (только из tick()),
    // поэтому изоляция main-актора им не нужна — помечаем nonisolated(unsafe).
    nonisolated(unsafe) private let cpuSensor = CPUSensor()
    nonisolated(unsafe) private let memSensor = MemorySensor()
    nonisolated(unsafe) private let netSensor = NetworkSensor()
    nonisolated(unsafe) private let smcService = SMCService()

    private var timer: PollingTimer!
    private let workQueue = DispatchQueue(label: "macmon.poll", qos: .utility)
    nonisolated(unsafe) private var tickCount = 0

    init() {
        timer = PollingTimer { [weak self] in self?.tick() }
        tick()            // мгновенный первый замер
        restartTimer()
    }

    private func restartTimer() {
        let interval = PollInterval(rawValue: pollIntervalRaw)?.rawValue ?? 2
        timer.restart(interval: interval)
    }

    /// Форсировать один внеочередной тик (кнопка refresh).
    func refresh() { tick() }

    /// Один цикл опроса. Тяжёлые чтения — в фоне, обновление @Published — на главном.
    private func tick() {
        let n = tickCount
        tickCount &+= 1
        let interval = PollInterval(rawValue: pollIntervalRaw)?.rawValue ?? 2

        workQueue.async { [weak self] in
            guard let self else { return }

            let cpu = self.cpuSensor.read()
            let mem = self.memSensor.read()
            let net = self.netSensor.read()

            // SMC дороже — опрашиваем не чаще раза в ~2 тика при интервале 1с.
            let pollSMC = interval >= 2 || (n % 2 == 0)
            let smc: SMCReading? = pollSMC ? self.smcService.read() : nil

            Task { @MainActor in
                self.cpuUsage = cpu
                self.memory = mem
                self.network = net
                if let smc {
                    self.cpuTemp = smc.cpuTemperature
                    self.fans = smc.fans
                }
            }
        }
    }

    // MARK: - Статусы (с учётом настраиваемого порога температуры)

    var cpuStatus: MetricStatus { MetricStatus.by(percent: cpuUsage, warm: 60, hot: 85) }
    var ramStatus: MetricStatus { MetricStatus.by(percent: memory.percent, warm: 70, hot: 90) }
    var tempStatus: MetricStatus {
        guard let t = cpuTemp else { return .normal }
        let warm = max(40, tempThreshold - 15)   // warm-граница ниже настраиваемой hot-границы
        if t >= tempThreshold { return .hot }
        if t >= warm { return .warm }
        return .normal
    }
}
