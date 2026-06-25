import SwiftUI

/// Экран настроек: автозапуск, интервал опроса, порог температуры, состав menubar-индикатора.
struct SettingsView: View {
    @EnvironmentObject var store: MetricsStore
    @Environment(\.dismiss) private var dismiss

    @State private var launchAtLogin = LaunchAtLogin.isEnabled
    @State private var launchError: String?

    @AppStorage("menuBarItems") private var itemsRaw: String = MenuBarItem.cpu.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Настройки").font(.system(size: 15, weight: .semibold))
                Spacer()
                Button("Готово") { dismiss() }.keyboardShortcut(.defaultAction)
            }

            // 1. Автозапуск.
            section("Запуск при входе") {
                Toggle("Запускать MacMon при входе в систему", isOn: $launchAtLogin)
                    .toggleStyle(.switch)
                    .onChange(of: launchAtLogin) { _, newValue in
                        do {
                            try LaunchAtLogin.set(newValue)
                            launchError = nil
                        } catch {
                            launchError = error.localizedDescription
                            launchAtLogin = LaunchAtLogin.isEnabled   // откатить тумблер к реальности
                        }
                    }
                if let launchError {
                    Text(launchError).font(.caption).foregroundStyle(Theme.hot)
                }
            }

            // 2. Интервал опроса.
            section("Интервал опроса") {
                Picker("", selection: Binding(
                    get: { PollInterval(rawValue: store.pollIntervalRaw) ?? .two },
                    set: { store.pollIntervalRaw = $0.rawValue })
                ) {
                    ForEach(PollInterval.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // 3. Порог температуры (граница warm/hot).
            section("Порог температуры (hot)") {
                HStack {
                    Slider(value: $store.tempThreshold, in: 75...95, step: 1)
                    Text("\(Int(store.tempThreshold))°C")
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 48, alignment: .trailing)
                }
            }

            // 4. Состав индикатора в строке меню.
            section("Показывать в строке меню") {
                ForEach(MenuBarItem.allCases) { item in
                    Toggle(item.title, isOn: bindingFor(item))
                        .toggleStyle(.checkbox)
                }
            }
        }
        .padding(20)
        .frame(width: 340)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.system(size: 12, weight: .semibold)).foregroundStyle(.secondary)
            content()
        }
    }

    private func bindingFor(_ item: MenuBarItem) -> Binding<Bool> {
        Binding(
            get: { selected.contains(item) },
            set: { isOn in
                var set = selected
                if isOn { if !set.contains(item) { set.append(item) } }
                else { set.removeAll { $0 == item } }
                // Сохраняем в исходном порядке CaseIterable для стабильности.
                let ordered = MenuBarItem.allCases.filter { set.contains($0) }
                itemsRaw = ordered.map(\.rawValue).joined(separator: ",")
            })
    }

    private var selected: [MenuBarItem] {
        itemsRaw.split(separator: ",").compactMap { MenuBarItem(rawValue: String($0)) }
    }
}
