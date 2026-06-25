import Foundation
import Darwin

/// Загрузка CPU (%) по дельте тиков между опросами через `host_processor_info`.
final class CPUSensor: Sensor {
    private var previousTicks: [UInt32]?   // [user, system, idle, nice] суммарно по всем ядрам

    /// Возвращает агрегированную загрузку 0…100.
    func read() -> Double {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0

        let result = host_processor_info(mach_host_self(),
                                         PROCESSOR_CPU_LOAD_INFO,
                                         &cpuCount,
                                         &info,
                                         &infoCount)
        guard result == KERN_SUCCESS, let info else { return 0 }

        defer {
            let size = vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), size)
        }

        // Суммируем тики по всем ядрам.
        var user: UInt32 = 0, system: UInt32 = 0, idle: UInt32 = 0, nice: UInt32 = 0
        let states = Int(CPU_STATE_MAX)
        for core in 0..<Int(cpuCount) {
            let base = core * states
            user   &+= UInt32(bitPattern: info[base + Int(CPU_STATE_USER)])
            system &+= UInt32(bitPattern: info[base + Int(CPU_STATE_SYSTEM)])
            idle   &+= UInt32(bitPattern: info[base + Int(CPU_STATE_IDLE)])
            nice   &+= UInt32(bitPattern: info[base + Int(CPU_STATE_NICE)])
        }

        let ticks = [user, system, idle, nice]
        defer { previousTicks = ticks }

        guard let prev = previousTicks else { return 0 }  // первый замер — нет дельты

        let dUser   = Double(user   &- prev[0])
        let dSystem = Double(system &- prev[1])
        let dIdle   = Double(idle   &- prev[2])
        let dNice   = Double(nice   &- prev[3])

        let busy  = dUser + dSystem + dNice
        let total = busy + dIdle
        guard total > 0 else { return 0 }
        return max(0, min(100, busy / total * 100))
    }
}
