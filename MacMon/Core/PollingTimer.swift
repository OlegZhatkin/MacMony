import Foundation

/// Создаёт/пересоздаёт таймер под текущий интервал. Тик уходит в `onTick` на главном потоке.
final class PollingTimer {
    private var timer: Timer?
    private let onTick: () -> Void

    init(onTick: @escaping () -> Void) {
        self.onTick = onTick
    }

    /// (Пере)запускает таймер с заданным интервалом (сек).
    func restart(interval: TimeInterval) {
        stop()
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.onTick()
        }
        t.tolerance = interval * 0.1   // даём планировщику свободу — экономим энергию
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit { stop() }
}
