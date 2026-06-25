import Foundation
import Darwin

struct MemoryReading {
    let usedBytes: Double
    let totalBytes: Double
    var percent: Double { totalBytes > 0 ? usedBytes / totalBytes * 100 : 0 }
}

/// Заполненность RAM через `host_statistics64` (HOST_VM_INFO64).
final class MemorySensor: Sensor {
    private let total = Double(ProcessInfo.processInfo.physicalMemory)
    private let pageSize: Double = {
        var size: vm_size_t = 0
        host_page_size(mach_host_self(), &size)
        return Double(size)
    }()

    func read() -> MemoryReading {
        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        let result = withUnsafeMutablePointer(to: &stats) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else {
            return MemoryReading(usedBytes: 0, totalBytes: total)
        }

        // Использовано ≈ (active + wired + compressed) * page_size.
        let active     = Double(stats.active_count)
        let wired      = Double(stats.wire_count)
        let compressed = Double(stats.compressor_page_count)
        let used = (active + wired + compressed) * pageSize

        return MemoryReading(usedBytes: min(used, total), totalBytes: total)
    }
}
