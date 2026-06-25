import SwiftUI

/// Главное окно со всеми метриками в стиле liquid glass.
struct PopoverView: View {
    @EnvironmentObject var store: MetricsStore
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            VStack(spacing: 12) {
                MetricRow(icon: "cpu",
                          label: "CPU",
                          value: String(format: "%.0f%%", store.cpuUsage),
                          fraction: store.cpuUsage / 100,
                          status: store.cpuStatus,
                          accent: Theme.cpuAccent)

                MetricRow(icon: "thermometer.medium",
                          label: "Температура",
                          value: Fmt.temp(store.cpuTemp),
                          fraction: tempFraction,
                          status: store.tempStatus)

                MetricRow(icon: "memorychip",
                          label: "RAM",
                          value: ramValue,
                          fraction: store.memory.percent / 100,
                          status: store.ramStatus)

                fansSection
            }

            Divider().opacity(0.5)
            NetworkFooter(down: store.network.downBytesPerSec, up: store.network.upBytesPerSec)
        }
        .padding(16)
        .frame(width: Theme.popoverWidth)
        .background(GlassBackground())
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(store)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.cpuAccent)
            Text("MacMon")
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            Button { store.refresh() } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Обновить")

            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.plain)
            .help("Настройки")

            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.plain)
            .help("Выйти")
        }
        .font(.system(size: 13))
        .foregroundStyle(.secondary)
    }

    @ViewBuilder
    private var fansSection: some View {
        if store.fans.isEmpty {
            MetricRow(icon: "fanblades",
                      label: "Вентиляторы",
                      value: "—",
                      fraction: 0,
                      status: .normal)
        } else {
            ForEach(store.fans) { fan in
                MetricRow(icon: "fanblades",
                          label: store.fans.count > 1 ? "Вентилятор \(fan.index + 1)" : "Вентилятор",
                          value: "\(fan.current) RPM",
                          fraction: fan.fraction,
                          status: fan.status)
            }
        }
    }

    private var tempFraction: Double {
        guard let t = store.cpuTemp else { return 0 }
        // Шкала примерно 30…(порог+10)°C для наглядности.
        let lo = 30.0, hi = store.tempThreshold + 10
        return max(0, min(1, (t - lo) / (hi - lo)))
    }

    private var ramValue: String {
        "\(Fmt.gb(store.memory.usedBytes)) / \(Fmt.gb(store.memory.totalBytes))"
    }
}

/// Блок сети: две колонки Down / Up со стрелками.
struct NetworkFooter: View {
    let down: Double
    let up: Double

    var body: some View {
        HStack(spacing: 0) {
            column(icon: "arrow.down", title: "Download", value: Fmt.speed(down), color: Theme.netDown)
            Divider().frame(height: 28).opacity(0.4)
            column(icon: "arrow.up", title: "Upload", value: Fmt.speed(up), color: Theme.netUp)
        }
    }

    private func column(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
}

/// Системный материал (liquid glass) с тонким верхним хайлайтом.
struct GlassBackground: View {
    var body: some View {
        ZStack {
            VisualEffectBackground(material: .popover, blending: .behindWindow)
            RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.25), .white.opacity(0.02)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
    }
}

/// Обёртка над NSVisualEffectView — настоящий системный материал, адаптивный к теме.
struct VisualEffectBackground: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blending: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blending
        v.state = .active
        return v
    }
    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blending
    }
}
