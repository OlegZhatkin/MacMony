import SwiftUI

/// Встроенная карточка настроек (внутри popover): автозапуск, интервал опроса,
/// порог температуры, состав menubar-индикатора. Все настройки персистентны (@AppStorage).
struct SettingsCard: View {
    @EnvironmentObject var store: MetricsStore

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    @AppStorage("menuBarItems") private var itemsRaw: String = MenuBarItem.cpu.rawValue

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 7) {
                    Image(systemName: "gearshape")
                    Text("НАСТРОЙКИ").font(.system(size: 12, weight: .bold)).tracking(0.5)
                }
                .foregroundStyle(.secondary)

                // 1. Автозапуск.
                HStack(spacing: 10) {
                    rowIcon("rocket", Theme.rocket)
                    Text("Запуск при входе").font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: launchAtLogin) { _, newValue in
                            do { try LaunchAtLogin.set(newValue); launchError = nil }
                            catch {
                                launchError = error.localizedDescription
                                launchAtLogin = LaunchAtLogin.isEnabled
                            }
                        }
                }
                if let launchError {
                    Text(launchError).font(.caption).foregroundStyle(Theme.hot)
                }

                // 2. Интервал опроса.
                HStack(spacing: 10) {
                    rowIcon("clock", Theme.clock)
                    Text("Интервал опроса").font(.system(size: 13))
                    Spacer()
                    Picker("", selection: Binding(
                        get: { PollInterval(rawValue: store.pollIntervalRaw) ?? .two },
                        set: { store.pollIntervalRaw = $0.rawValue })
                    ) {
                        ForEach(PollInterval.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                }

                // 3. Порог температуры (граница warm/hot).
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        rowIcon("thermometer.medium", Theme.hot)
                        Text("Порог температуры").font(.system(size: 13))
                        Spacer()
                        Text("\(Int(store.tempThreshold))°C")
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    GradientThresholdSlider(value: $store.tempThreshold, range: 75...95)
                    legend
                }

                // 4. Состав индикатора в строке меню.
                VStack(alignment: .leading, spacing: 8) {
                    Text("ПОКАЗЫВАТЬ В СТРОКЕ МЕНЮ")
                        .font(.system(size: 11, weight: .bold)).tracking(0.5)
                        .foregroundStyle(.secondary)
                    ForEach(MenuBarItem.allCases) { item in
                        Toggle(item.title, isOn: bindingFor(item))
                            .toggleStyle(.checkbox)
                            .font(.system(size: 13))
                    }
                }
            }
        }
    }

    private func rowIcon(_ name: String, _ color: Color) -> some View {
        Image(systemName: name)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 18)
    }

    private var legend: some View {
        let warm = Int(max(40, store.tempThreshold - 15))
        let hot = Int(store.tempThreshold)
        return HStack(spacing: 14) {
            legendDot(Theme.normal, "норма <\(warm)°")
            legendDot(Theme.warm, "warm \(warm)–\(hot)°")
            legendDot(Theme.hot, "hot >\(hot)°")
        }
        .font(.system(size: 10, design: .monospaced))
        .foregroundStyle(.secondary)
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
        }
    }

    private func bindingFor(_ item: MenuBarItem) -> Binding<Bool> {
        Binding(
            get: { selected.contains(item) },
            set: { isOn in
                var set = selected
                if isOn { if !set.contains(item) { set.append(item) } }
                else { set.removeAll { $0 == item } }
                let ordered = MenuBarItem.allCases.filter { set.contains($0) }
                itemsRaw = ordered.map(\.rawValue).joined(separator: ",")
            })
    }

    private var selected: [MenuBarItem] {
        itemsRaw.split(separator: ",").compactMap { MenuBarItem(rawValue: String($0)) }
    }
}

/// Кастомный слайдер с градиентной шкалой температуры (норма→warm→hot).
struct GradientThresholdSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let span = range.upperBound - range.lowerBound
            let frac = span > 0 ? (value - range.lowerBound) / span : 0
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.tempGradient).frame(height: 6)
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(x: max(0, min(w - 16, CGFloat(frac) * w - 8)))
            }
            .frame(height: 16)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { g in
                let f = max(0, min(1, g.location.x / w))
                value = (range.lowerBound + Double(f) * span).rounded()
            })
        }
        .frame(height: 16)
    }
}
