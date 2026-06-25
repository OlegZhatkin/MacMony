import Foundation

/// Общий протокол сенсора — читает одно «измерение» и возвращает значение типа `Reading`.
/// Изолирует системные/C-вызовы за чистым Swift-интерфейсом, позволяет мокать в тестах.
protocol Sensor {
    associatedtype Reading
    func read() -> Reading
}
