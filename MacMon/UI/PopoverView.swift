import SwiftUI

/// Главное окно: градиентный фон + стеклянные карточки (метрики и настройки).
/// Настройки встроены в тот же popover (inline), а НЕ в отдельный sheet — иначе
/// MenuBarExtra-окно теряло фокус и закрывалось при клике по контролу.
struct PopoverView: View {
    @EnvironmentObject var store: MetricsStore
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 14) {
            metricsCard
            if showSettings {
                SettingsCard()
                    .environmentObject(store)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            footer
        }
        .padding(14)
        .frame(width: Theme.popoverWidth)
        .background(Theme.bgGradient)
    }

    // MARK: - Карточка метрик

    private var metricsCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                header

                VStack(spacing: 13) {
                    MetricRow(icon: "cpu",
                              label: "CPU",
                              value: String(format: "%.0f%%", store.cpuUsage),
                              fraction: store.cpuUsage / 100,
                              status: store.cpuStatus,
                              accent: Theme.cpuAccent)

                    MetricRow(icon: "thermometer.medium",
                              label: "Температура CPU",
                              value: Fmt.temp(store.cpuTemp),
                              fraction: tempFraction,
                              status: store.tempStatus)

                    MetricRow(icon: "memorychip",
                              label: "Память",
                              value: ramValue,
                              fraction: store.memory.percent / 100,
                              status: store.ramStatus,
                              accent: Theme.ramAccent)

                    fanRow
                }

                Divider().overlay(Color.white.opacity(0.12))
                NetworkFooter(down: store.network.downBytesPerSec, up: store.network.upBytesPerSec)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.normal)
            Text("MacMon").font(.system(size: 15, weight: .semibold))
            Spacer()
            iconButton("arrow.clockwise", help: "Обновить") { store.refresh() }
            iconButton("gearshape", help: "Настройки") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                    showSettings.toggle()
                }
            }
            iconButton("power", help: "Выйти") { NSApp.terminate(nil) }
        }
        .foregroundStyle(.secondary)
    }

    private func iconButton(_ name: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name).font(.system(size: 13, weight: .semibold))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    /// Вентиляторы — без бара, через « · ».
    private var fanRow: some View {
        HStack(spacing: 7) {
            Image(systemName: "fanblades")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text("Вентиляторы").font(.system(size: 12, weight: .medium))
            Spacer(minLength: 8)
            Text(fanValue)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(store.fans.isEmpty ? Color.secondary : .primary)
        }
    }

    private var fanValue: String {
        guard !store.fans.isEmpty else { return "—" }
        let rpms = store.fans.map { "\($0.current)" }.joined(separator: " · ")
        return "\(rpms) RPM"
    }

    private var footer: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.clockwise")
            Text("Данные обновляются автоматически — рефрешить вручную не нужно")
        }
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
    }

    private var tempFraction: Double {
        guard let t = store.cpuTemp else { return 0 }
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
            column(icon: "arrow.down", title: "Down", value: Fmt.speed(down), color: Theme.netDown)
            Divider().frame(height: 34).overlay(Color.white.opacity(0.12))
            column(icon: "arrow.up", title: "Up", value: Fmt.speed(up), color: Theme.netUp)
        }
    }

    private func column(icon: String, title: String, value: String, color: Color) -> some View {
        let parts = value.split(separator: " ", maxSplits: 1)
        let number = String(parts.first ?? "")
        let unit = parts.count > 1 ? String(parts[1]) : ""
        return VStack(spacing: 3) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 12, weight: .bold))
                Text(title).font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(color)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(number).font(.system(size: 18, weight: .semibold, design: .monospaced))
                Text(unit).font(.system(size: 10)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
