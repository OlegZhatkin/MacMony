import Foundation
import Darwin

struct NetworkReading {
    let downBytesPerSec: Double
    let upBytesPerSec: Double
}

/// Скорость сети через `getifaddrs`: дельта счётчиков байт по времени.
final class NetworkSensor: Sensor {
    private var prevIn: UInt64 = 0
    private var prevOut: UInt64 = 0
    private var prevTime: TimeInterval = 0

    func read() -> NetworkReading {
        var totalIn: UInt64 = 0
        var totalOut: UInt64 = 0

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else {
            return NetworkReading(downBytesPerSec: 0, upBytesPerSec: 0)
        }
        defer { freeifaddrs(ifaddr) }

        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let cur = ptr {
            defer { ptr = cur.pointee.ifa_next }

            let addr = cur.pointee.ifa_addr
            guard let addr, addr.pointee.sa_family == UInt8(AF_LINK) else { continue }

            let name = String(cString: cur.pointee.ifa_name)
            if name == "lo0" { continue }  // исключаем loopback

            // Только активные (running) интерфейсы.
            let flags = Int32(cur.pointee.ifa_flags)
            guard (flags & IFF_RUNNING) != 0 else { continue }

            if let data = cur.pointee.ifa_data?.assumingMemoryBound(to: if_data.self) {
                totalIn  &+= UInt64(data.pointee.ifi_ibytes)
                totalOut &+= UInt64(data.pointee.ifi_obytes)
            }
        }

        let now = ProcessInfo.processInfo.systemUptime
        defer { prevIn = totalIn; prevOut = totalOut; prevTime = now }

        guard prevTime > 0 else { return NetworkReading(downBytesPerSec: 0, upBytesPerSec: 0) }
        let dt = now - prevTime
        guard dt > 0 else { return NetworkReading(downBytesPerSec: 0, upBytesPerSec: 0) }

        // Защита от переполнения счётчика/сброса интерфейса.
        let down = totalIn  >= prevIn  ? Double(totalIn  - prevIn)  / dt : 0
        let up   = totalOut >= prevOut ? Double(totalOut - prevOut) / dt : 0
        return NetworkReading(downBytesPerSec: down, upBytesPerSec: up)
    }
}
